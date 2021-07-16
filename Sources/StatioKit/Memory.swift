//
//  File.swift
//  
//
//  Created by Varun Santhanam on 7/16/21.
//

import Foundation

public enum Memory {
    
    public enum Error: Swift.Error {
        case unknown
    }
    
    public struct Snapshot: Equatable, Hashable {
        
        public init(physicalMemory: UInt64,
                    freeMemory: UInt64,
                    active: UInt64,
                    inactive: UInt64,
                    wired: UInt64,
                    pageIns: UInt64,
                    pageOuts: UInt64) {
            self.physicalMemory = physicalMemory
            self.freeMemory = freeMemory
            self.active = active
            self.inactive = inactive
            self.wired = wired
            self.pageIns = pageIns
            self.pageOuts = pageOuts
        }
        
        public let physicalMemory: UInt64
        public let freeMemory: UInt64
        public let active: UInt64
        public let inactive: UInt64
        public let wired: UInt64
        public let pageIns: UInt64
        public let pageOuts: UInt64
    }
    
    public static func record() throws -> Snapshot {
        let physical = ProcessInfo.processInfo.physicalMemory

        let host_port: mach_port_t = mach_host_self()
        var host_size = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        var page_size: vm_size_t = 0
        host_page_size(host_port, &page_size)
        var vm_stat: vm_statistics = vm_statistics_data_t()

        let stat_size = MemoryLayout.size(ofValue: vm_stat)
        let status: kern_return_t = withUnsafeMutableBytes(of: &vm_stat) { value in
            let bound_pointer = value.baseAddress?.bindMemory(to: Int32.self, capacity: stat_size / MemoryLayout<Int32>.stride)
            return host_statistics(host_port, HOST_VM_INFO, bound_pointer, &host_size)
        }

        guard status == KERN_SUCCESS else {
            throw Error.unknown
        }

        let free = (UInt64)((vm_size_t)(vm_stat.free_count) * page_size)
        let active = (UInt64)((vm_size_t)(vm_stat.active_count) * page_size)
        let inactive = (UInt64)((vm_size_t)(vm_stat.inactive_count) * page_size)
        let wired = (UInt64)((vm_size_t)(vm_stat.wire_count) * page_size)
        let pageins = (UInt64)(vm_stat.pageins)
        let pageouts = (UInt64)(vm_stat.pageouts)

        return .init(physicalMemory: physical,
                     freeMemory: free,
                     active: active,
                     inactive: inactive,
                     wired: wired,
                     pageIns: pageins,
                     pageOuts: pageouts)
    }
    
}
