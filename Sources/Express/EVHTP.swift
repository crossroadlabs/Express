//===--- EVHTP.swift ------------------------------------------------------===//
//
//Copyright (c) 2015-2016 Daniel Leping (dileping)
//
//This file is part of Swift Express.
//
//Swift Express is free software: you can redistribute it and/or modify
//it under the terms of the GNU Lesser General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//Swift Express is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU Lesser General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public License
//along with Swift Express.  If not, see <http://www.gnu.org/licenses/>.
//
//===----------------------------------------------------------------------===//

import Foundation
import CEVHTP
import Result
import ExecutionContext
import Future
import CEvent

#if os(Linux)
    import Glibc
#endif

internal typealias EVHTPp = UnsafeMutablePointer<evhtp_t>?
internal typealias EVHTPRequest = UnsafeMutablePointer<evhtp_request_t>
internal typealias EVHTPRouteCallback = (EVHTPRequest) -> ()
internal typealias EVHTPCallback = UnsafeMutablePointer<evhtp_callback_t>

class EVHTPBuffer {
    let cbuf: OpaquePointer
    let free: Bool
    let wnCb: ((EVHTPBuffer, Array<UInt8>) -> ())?
    init() {
        cbuf = evbuffer_new()
        free = true
        wnCb = nil
    }
    init(buf: OpaquePointer) {
        cbuf = buf
        free = false
        wnCb = nil
    }
    init(writeNotification:@escaping (EVHTPBuffer, Array<UInt8>) -> ()) {
        cbuf = evbuffer_new()
        free = true
        wnCb = writeNotification
    }
    init(buf: OpaquePointer, writeNotification: @escaping (EVHTPBuffer, Array<UInt8>) -> ()) {
        cbuf = buf
        wnCb = writeNotification
        free = false
    }
    deinit {
        if free {
            evbuffer_free(cbuf)
        }
    }
    func write(data: Array<UInt8>) -> Int32 {
        let result = evbuffer_add(cbuf, data, data.count)
        if result == 0 && wnCb != nil {
            wnCb!(self, data)
        }
        return result
    }
    func read(bytes: Int) -> Array<UInt8> {
        let mbuf:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: bytes)
        let readed = evbuffer_remove(cbuf, mbuf, bytes)
        let arr = Array<UInt8>(UnsafeBufferPointer<UInt8>(start: mbuf, count: Int(readed)))
        mbuf.deinitialize()
        mbuf.deallocate(capacity: bytes)
        return arr
    }
    func length() -> Int {
        return evbuffer_get_length(cbuf)
    }
}

private class HeadersDict {
    var dict: Dictionary<String, String>
    
    init() {
        dict = Dictionary<String, String>()
    }
    init(dict: Dictionary<String, String>) {
        self.dict = dict
    }
    
    func writeHeaders(headers: UnsafeMutablePointer<evhtp_kvs_t>) {
        for (k,v) in dict {
            let kvheader = evhtp_kv_new(k, v, 1, 1)
            evhtp_kvs_add_kv(headers, kvheader)
        }
    }
    
    static func fromHeaders(headers: UnsafeMutablePointer<evhtp_kvs_t>) -> HeadersDict {
        var headData = HeadersDict()
        
        evhtp_kvs_for_each(headers, { (kv, arg) -> Int32 in

            if let arg = UnsafeMutablePointer<HeadersDict>(OpaquePointer(arg)), let kv = kv {
                arg.pointee.addHeader(key: kv.pointee.key, klen: kv.pointee.klen, val: kv.pointee.val, vlen: kv.pointee.vlen)
            }
            return 0
        }, &headData)
        
        return headData
    }
    
    private func addHeader(key: UnsafeMutablePointer<Int8>, klen: Int, val: UnsafeMutablePointer<Int8>, vlen: Int) {
        let k = String(bytesNoCopy: key, length: klen, encoding: String.Encoding.utf8, freeWhenDone: false)
        let v = String(bytesNoCopy: val, length: vlen, encoding: String.Encoding.utf8, freeWhenDone: false)
        dict[k!] = v
    }
}

private class RepeatingHeaderDict {
    var dict: Dictionary<String, Array<String>>
    init() {
        dict = Dictionary<String, Array<String>>()
    }
    init(dict: Dictionary<String, Array<String>>) {
        self.dict = dict
    }
    
    func writeHeaders(headers: UnsafeMutablePointer<evhtp_kvs_t>) {
        for (k,vs) in dict {
            for v in vs {
                let kvheader = evhtp_kv_new(k, v, 1, 1)
                evhtp_kvs_add_kv(headers, kvheader)
            }
        }
    }
    
    static func fromHeaders(headers: UnsafeMutablePointer<evhtp_kvs_t>?) -> RepeatingHeaderDict {
        var headData = RepeatingHeaderDict()
        
        evhtp_kvs_for_each(headers, { (kv, arg) -> (Int32) in
            
            if let arg = UnsafeMutablePointer<RepeatingHeaderDict>(OpaquePointer(arg)), let kv = kv {
                arg.pointee.addHeader(key: kv.pointee.key, klen: kv.pointee.klen, val: kv.pointee.val, vlen: kv.pointee.vlen)
            }
            return 0
        }, &headData)
        return headData
    }
    
    
    
    private func addHeader(key: UnsafeMutablePointer<Int8>, klen: Int, val: UnsafeMutablePointer<Int8>, vlen: Int) {
        var unk:UnsafeMutablePointer<UInt8>? = UnsafeMutablePointer<UInt8>.allocate(capacity: klen)
        var unv:UnsafeMutablePointer<UInt8>?  = UnsafeMutablePointer<UInt8>.allocate(capacity: vlen)
        
        var k:String?
        var v:String?

        key.withMemoryRebound(to: UInt8.self, capacity: klen){key in
            if evhtp_unescape_string(&unk, key , klen) == 0 {
                unk!.withMemoryRebound(to: Int8.self, capacity: klen) {iunk in
                    k = String(bytesNoCopy: unk!, length: strnlen(iunk, klen), encoding: String.Encoding.utf8, freeWhenDone: false)
                }
            } else {
                k = String(bytesNoCopy: key, length: klen, encoding: String.Encoding.utf8, freeWhenDone: false)
            }
        }
    
        
        val.withMemoryRebound(to: UInt8.self, capacity: vlen){val in
            
            if evhtp_unescape_string(&unv, val , vlen) == 0 {
                unv!.withMemoryRebound(to: Int8.self, capacity: vlen){iunv in
                    v = String(bytesNoCopy: unv!, length: strnlen(iunv, vlen), encoding: String.Encoding.utf8, freeWhenDone: false)
                }
            } else {
                v = String(bytesNoCopy: val, length: vlen, encoding: String.Encoding.utf8, freeWhenDone: false)
            }
        }
      
        
        if var a = dict[k!] {
            a.append(v!)
        } else {
            dict[k!] = [v!]
        }
        unk!.deinitialize()
        unk!.deallocate(capacity: klen)
        unv!.deinitialize()
        unv!.deallocate(capacity: vlen)
    }
}

private class DataReadParams {
    let end: Promise<Void>
    let consumer: DataConsumerType
    init(consumer: DataConsumerType, end: Promise<Void>) {
        self.consumer = consumer
        self.end = end
    }
}

private func request_callback(req: EVHTPRequest?, callbk: UnsafeMutableRawPointer?) {
    let callback = UnsafeMutablePointer<EVHTPRouteCallback>(OpaquePointer(callbk)!).pointee
    callback(req!)
    evhtp_request_pause(req)
}

private func sockaddr_size(saddr: UnsafeMutablePointer<sockaddr>) -> Int {
    #if os(Linux)
        switch Int32(saddr.memory.sa_family) {
            case AF_INET:
                return strideof(sockaddr_in)
            case AF_INET6:
                return strideof(sockaddr_in6)
            case AF_LOCAL:
                return strideof(sockaddr_un)
            default:
                return 0
        }
    #else
        return Int(saddr.pointee.sa_len)
    #endif
}

internal class EVHTPRequestInfo {
    private let req:EVHTPRequest


    
    var headers: Dictionary<String, String> {
        get {
            return HeadersDict.fromHeaders(headers: req.pointee.headers_in).dict
        }
    }
    
    var method: String {
        get {
            switch evhtp_request_get_method(req) {
            case htp_method_GET:
                return "GET"
            case htp_method_HEAD:
                return "HEAD"
            case htp_method_POST:
                return "POST"
            case htp_method_PUT:
                return "PUT"
            case htp_method_DELETE:
                return "DELETE"
            case htp_method_MKCOL:
                return "MKCOL"
            case htp_method_COPY:
                return "COPY"
            case htp_method_MOVE:
                return "MOVE"
            case htp_method_OPTIONS:
                return "OPTIONS"
            case htp_method_PROPFIND:
                return "PROPFIND"
            case htp_method_PROPPATCH:
                return "PROPPATCH"
            case htp_method_LOCK:
                return "LOCK"
            case htp_method_UNLOCK:
                return "UNLOCK"
            case htp_method_TRACE:
                return "TRACE"
            case htp_method_CONNECT:
                return "CONNECT"
            case htp_method_PATCH:
                return "PATCH"
            default:
                return "UNKNOWN"
            }
        }
    }
    
    var version: String {
        get {
            switch req.pointee.proto {
            case EVHTP_PROTO_10:
                return "1.0"
            case EVHTP_PROTO_11:
                return "1.1"
            default:
                return "INVALID"
            }
        }
    }
    var path: String {
        get {
            let p = String(validatingUTF8: req.pointee.uri.pointee.path.pointee.full)
            if p != nil {
                return p!
            }
            return ""
        }
    }
    var uri: String {
        get {
            var p = path
            let uri = req.pointee.uri.pointee
            
            let q = UnsafePointer<CChar>(OpaquePointer(uri.query_raw)).flatMap(String.init(validatingUTF8:))
            if q != nil && q != "" {
                p = p + "?" + q!
            }
            let f = UnsafePointer<CChar>(OpaquePointer(uri.fragment)).flatMap(String.init(validatingUTF8:))
            
            if f != nil && f != "" {
                p = p + "#" + f!
            }
            return p
        }
    }
    var host: String {
        get {
            var h = String(validatingUTF8: req.pointee.uri.pointee.authority.pointee.hostname)
            if h != nil {
                let p = req.pointee.uri.pointee.authority.pointee.port
                if p > 0 {
                    h = h! + ":" + String(p)
                }
                return h!
            }
            return ""
        }
    }
    var username: String? {
        get {
            return String(validatingUTF8: req.pointee.uri.pointee.authority.pointee.username)
        }
    }
    var password: String? {
        get {
            return String(validatingUTF8: req.pointee.uri.pointee.authority.pointee.password)
        }
    }
    var scheme: String {
        get {
            switch req.pointee.uri.pointee.scheme {
            case htp_scheme_none:
                return "NONE"
            case htp_scheme_ftp:
                return "FTP"
            case htp_scheme_http:
                return "HTTP"
            case htp_scheme_https:
                return "HTTPS"
            case htp_scheme_nfs:
                return "NFS"
            default:
                return "UNKNOWN"
            }
        }
    }
    var remoteIp: String {
        get {
            let mbuf = UnsafeMutablePointer<CChar>.allocate(capacity: Int(INET6_ADDRSTRLEN))
            let err = getnameinfo(req.pointee.conn.pointee.saddr, UInt32(sockaddr_size(saddr: req.pointee.conn.pointee.saddr)), mbuf, UInt32(INET6_ADDRSTRLEN), nil, 0, NI_NUMERICHOST)
            
            
            
            var res = ""
            if err == 0 {
                let t = String(validatingUTF8: mbuf)
                if t != nil {
                    res = t!
                }
            }
            mbuf.deinitialize()
            mbuf.deallocate(capacity: Int(INET6_ADDRSTRLEN))
            return res
        }
    }
    var query: Dictionary<String,Array<String>> {
        get {
            return RepeatingHeaderDict.fromHeaders(headers: req.pointee.uri.pointee.query).dict
        }
    }
    
    init(req: EVHTPRequest) {
        self.req = req
    }
}

internal class _evhtp {
    // Can't use EV_TIMEOUT from libevent, some name intersection with OS X module.
    let EV_TIMEOUT:Int16 = 1
    
    init() {
        evthread_use_pthreads()
    }
    
    func create_base() -> OpaquePointer {
        return event_base_new()
    }
    
    func create_htp(base: OpaquePointer) -> EVHTPp {
        let htp = evhtp_new(base, nil)
        evhtp_set_parser_flags(htp, EVHTP_PARSE_QUERY_FLAG_IGNORE_HEX | EVHTP_PARSE_QUERY_FLAG_ALLOW_EMPTY_VALS | EVHTP_PARSE_QUERY_FLAG_ALLOW_NULL_VALS | EVHTP_PARSE_QUERY_FLAG_TREAT_SEMICOLON_AS_SEP)
        return htp
    }
    
    func bind_address(htp: EVHTPp, host: String, port: UInt16) -> Int32 {
        return evhtp_bind_socket(htp, host, port, 1024)
    }
    
    func start_server_loop(base: OpaquePointer) {
        event_base_dispatch(base)
    }
    
    func start_event(base: OpaquePointer) -> Future<Void> {
        let p = Promise<Void>()
        
        event_base_once(base, -1, EV_TIMEOUT, { (fd: Int32, what: Int16, arg: UnsafeMutableRawPointer?) in
            try! Unmanaged<Promise<Void>>.fromOpaque(arg!).takeRetainedValue().success(value: ())
        }, UnsafeMutableRawPointer(Unmanaged.passRetained(p).toOpaque()), nil)
        
        return p.future
    }
    
    func add_simple_route(htp: EVHTPp, path: String, cb: @escaping EVHTPRouteCallback) -> EVHTPCallback {
        let cbp = UnsafeMutablePointer<EVHTPRouteCallback>.allocate(capacity: 1)
        cbp.initialize(to: cb)
        return evhtp_set_cb(htp, path, request_callback, UnsafeMutableRawPointer(cbp))
    }
    
    func add_general_route(htp: EVHTPp, cb: @escaping EVHTPRouteCallback) {
        let cbp = UnsafeMutablePointer<EVHTPRouteCallback>.allocate(capacity: 1)
        cbp.initialize(to: cb)
        evhtp_set_gencb(htp, request_callback, UnsafeMutableRawPointer(cbp))
    }
    
    func add_wildcard_route(htp: EVHTPp, wpath:String, cb: @escaping EVHTPRouteCallback) -> EVHTPCallback {
        let cbp = UnsafeMutablePointer<EVHTPRouteCallback>.allocate(capacity: 1)
        cbp.initialize(to: cb)
        return evhtp_set_glob_cb(htp, wpath, request_callback, cbp)
    }
    
    func get_request_info(req: EVHTPRequest) -> EVHTPRequestInfo {
        return EVHTPRequestInfo(req: req)
    }
    
    func read_data(req: EVHTPRequest, cb: (Array<UInt8>) -> Bool) {
        let buf = EVHTPBuffer(buf: req.pointee.buffer_in)
        var readed = 0
        repeat {
            let data = buf.read(bytes: 4096)
            readed = data.count
            if !cb(data) {
                break;
            }
        } while (readed > 0)
    }
    
    func start_response(req: EVHTPRequest, headers:Dictionary<String, String>, status: UInt16) -> EVHTPBuffer {
        HeadersDict(dict: headers).writeHeaders(headers: req.pointee.headers_out)
        evhtp_send_reply_chunk_start(req, status)
        return EVHTPBuffer(writeNotification: { (buf: EVHTPBuffer, data: Array<UInt8>) -> () in
            evhtp_send_reply_chunk(req, buf.cbuf)
        })
    }
    
    func finish_response(req: EVHTPRequest, buffer: EVHTPBuffer) {
        evhtp_send_reply_chunk_end(req)
        event_base_once(req.pointee.htp.pointee.evbase, -1, EV_TIMEOUT, { (fd: Int32, what: Int16, arg: UnsafeMutableRawPointer?) -> Void in
            evhtp_request_resume(EVHTPRequest(OpaquePointer(arg)!))
        }, req, nil)
    }
}

internal let EVHTP = _evhtp()

func evhtp_parse_query(query:String) -> [String: [String]] {
    let parsed = evhtp_parse_query_wflags(query, query.utf8.count,EVHTP_PARSE_QUERY_FLAG_IGNORE_HEX | EVHTP_PARSE_QUERY_FLAG_ALLOW_EMPTY_VALS | EVHTP_PARSE_QUERY_FLAG_ALLOW_NULL_VALS | EVHTP_PARSE_QUERY_FLAG_TREAT_SEMICOLON_AS_SEP)
    defer {
        evhtp_kvs_free(parsed)
    }
    return RepeatingHeaderDict.fromHeaders(headers: parsed!).dict
}
