//
//  BerTlv.swift
//  BoricaSDKDemo
//
//  Created by Flex on 10/12/15.
//  Copyright © 2015 Datecs. All rights reserved.
//

import Foundation

class BerTlv : NSObject {
    
    var tag: UInt64 = 0
    var data = [UInt8]()
    
    override init() {
        super.init()
    }
    
    func int32Value() -> Int {
        var r: Int = 0
        for b in data {
            r <<= 8
            r |= Int(b)
        }

        return r
    }

    func intValue() -> UInt64 {
        var r: UInt64 = 0
        for b in data {
            r <<= 8
            r |= UInt64(b)
        }
        
        return r
    }
    
    func boolValue() -> Bool {
        return (data.count > 0 && data[0] != 0)
    }
    
    func stringValue() -> String {
        return String(bytes: data, encoding: String.Encoding.ascii)!
    }
    
    func hexStringvalue() -> String {
        return data.toHexString()
    }

    func encode() -> [UInt8]? {
        let tags: [BerTlv] = [self]
        return BerTlv.encodeTags(tags)
    }

    class func encodeToBCD(_ value: UInt64, nBytes: Int) -> Data {
        var r = [UInt8]()
        var v = value
        for _ in 0..<nBytes {
            var b = UInt8(v % 10)
            v /= 10
            b |= UInt8((v % 10) << 4)
            v /= 10
            r.append(b)
        }
        return Data(bytes: UnsafePointer<UInt8>(r), count: r.count)
    }
    
    class func tlvWithBytes(_ data: [UInt8], tag: UInt64) -> BerTlv {
        let tlv = BerTlv()
        tlv.tag = tag
        tlv.data = data;
        return tlv;
    }
    
    class func tlvWithInt(_ data: UInt64, nBytes:Int, tag: UInt64) -> BerTlv {
        var r = [UInt8]()
        var d = data
        for _ in 0..<nBytes {
            r.append(UInt8(d))
            d >>= 8
        }
        return .tlvWithBytes(r, tag:tag)
    }
    
    class func tlvWithBCD(_ data: UInt64, nBytes:Int, tag: UInt64) -> BerTlv {
        let b = self.encodeToBCD(data, nBytes:nBytes)
        return self.tlvWithBytes(b.getBytes(), tag:tag)
    }
    
    class func tlvWithString(_ data: String, tag: UInt64) -> BerTlv {
        return self.tlvWithBytes(data.data(using: String.Encoding.ascii)!.getBytes(), tag:tag)
    }
    
    class func tlvWithHexString(_ data:String, tag:UInt64) -> BerTlv {
        return self.tlvWithBytes(data.dataFromHexadecimalString()!.getBytes(), tag:tag)
    }
    
    class func findTag(_ tag:UInt64, tags:[BerTlv]) -> [BerTlv] {
        var r = [BerTlv]()
        
        for t in tags {
            if (t.tag == tag) {
                r.append(t)
            }
        }
        return r
    }
    
    class func findLastTag(_ tag:UInt64, tags:[BerTlv]) -> BerTlv? {
        var r = self.findTag(tag, tags: tags)
        if r.count > 0 {
            return r[0]
        }
        return nil
    }
    
    class func decodeTags(_ data: [UInt8]) -> [BerTlv]? {
        
        if data.count == 0 {
            return nil
        }
        var r = [BerTlv]()
        
        var i = 0
        while i < data.count {
            let t = UInt64(data[i])
            i+=1

            let tlv = BerTlv()
            
            tlv.tag = t

            if t == 0xDF {
                tlv.tag = 0xDF
            }

            if (tlv.tag & 0x1F) == 0x1F {
                //long tag form
                repeat {
                    tlv.tag <<= 8
                    tlv.tag |= UInt64(data[i])
                    i += 1
                }while (tlv.tag & 0x80) != 0
            }


            var tagLen = 0
            
            if (data[i] & 0x80) != 0 {
                //long form
                let nBytes = data[i] & 0x7f
                i+=1
                for _ in 0..<nBytes {
                    tagLen <<= 8
                    tagLen |= Int(data[i])
                    i+=1
                }
            }else {
                //short form
                tagLen = Int(data[i]&0x7f)
                i+=1
            }
            if tagLen > 4096 {
                return nil
            }
            tlv.data=data.subArray(i, end: tagLen)
            
            r.append(tlv)
            
            i+=tagLen;
        }
        return r;
    }
    
    class func encodeTags(_ tags: [BerTlv]) -> [UInt8]? {
        
        var r = [UInt8]()
        for tag in tags {
            var tagLen = 0
            var t = tag.tag
            while (t & 0xff) != 0 {
                tagLen += 1
                t >>= 8
            }
            for i in 0..<tagLen {
                r.append(UInt8((tag.tag >> UInt64((tagLen-i-1) * 8)) & 0xff))
            }

            let i = r.count
            r.append(UInt8(tag.data.count & 0xff))

            if tag.data.count > 127 {
                //long form
                var tl = tag.data.count
                tagLen=0
                while tl != 0 {
                    r.insert(UInt8(tl & 0xff), at: i+1)
                    tagLen += 1
                    tl >>= 8
                }
                r[i]=UInt8(0x80 + tagLen)
            }
            r.append(contentsOf: tag.data)
        }
        
        return r;
    }
    
    class func createTagList(_ tags: [UInt64]) -> [UInt8] {
        var r = [UInt8]()
        
        for tag in tags {
            var tagLen = 0
            var t = tag
            for i in 0..<8 {
                if (t & 0xff) != 0 {
                    tagLen = (i+1)
                }
                t >>= 8
            }
            for i in 0..<tagLen {
                r.append(UInt8((tag >> UInt64((tagLen-i-1) * 8)) & 0xff))
            }
        }
        return r
    }
    
    override  var description: String {
        let str = self.data.toHexString()
        return String(format: "Tag: %X %@", self.tag, str)
    }
    
}
