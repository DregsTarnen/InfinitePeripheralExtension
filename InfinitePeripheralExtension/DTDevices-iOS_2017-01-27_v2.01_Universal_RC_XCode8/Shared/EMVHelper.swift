//
//  EMVHelper.swift
//  DemoPay
//
//  Created by Flex on 11/22/16.
//  Copyright © 2016 Flex. All rights reserved.
//

import Foundation

class EMVHelper {

    class func getConfigurationVesrsion(configuration: [UInt8]) -> Int32
    {
        guard let arr = BerTlv.decodeTags(configuration) else { return 0 }

        for tag in arr {
            if tag.tag == 0xE4 {
                guard let cfgtag = BerTlv.findLastTag(0xC1, tags: BerTlv.decodeTags(tag.data)!) else { return 0 }
                var ver: Int32 = 0
                for b in cfgtag.data {
                    ver <<= 8
                    ver |= Int32(b)
                }
                return ver
            }
        }

        return 0
    }

    class func parseTagData(node: XMLNode) -> [UInt8] {
        let tagid = node.attributes["id"]!.hexIntValue()

        if node.children.count > 0 {
            var data = [UInt8]()
            for cnode in node.children {
                data.append(contentsOf: parseTagData(node: cnode))
            }

            let tag = BerTlv.tlvWithBytes(data, tag: tagid)

            return tag.encode()!
        } else {
            let tag = BerTlv.tlvWithHexString(node.text, tag: tagid)

            return tag.encode()!
        }
    }

    class func getConfigurationFromXMLFile(configFile: String) throws -> [UInt8]? {
        let filePath = Bundle.main.resourcePath!.stringByAppendingPathComponent(path: configFile)
        let file = try NSString(contentsOfFile: filePath, encoding: String.Encoding.ascii.rawValue)

        let xml = XML(data: file.data(using: String.Encoding.ascii.rawValue)!)

        var data = [UInt8]()


        for node in xml[0].children {
            data.append(contentsOf: parseTagData(node: node))
        }

        return data
    }
}
