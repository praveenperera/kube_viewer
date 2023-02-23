// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!
import Foundation

// Depending on the consumer's build setup, the low-level FFI code
// might be in a separate module, or it might be compiled inline into
// this module. This is a bit of light hackery to work with both.
#if canImport(kube_viewerFFI)
import kube_viewerFFI
#endif

fileprivate extension RustBuffer {
    // Allocate a new buffer, copying the contents of a `UInt8` array.
    init(bytes: [UInt8]) {
        let rbuf = bytes.withUnsafeBufferPointer { ptr in
            RustBuffer.from(ptr)
        }
        self.init(capacity: rbuf.capacity, len: rbuf.len, data: rbuf.data)
    }

    static func from(_ ptr: UnsafeBufferPointer<UInt8>) -> RustBuffer {
        try! rustCall { ffi_kube_viewer_54fe_rustbuffer_from_bytes(ForeignBytes(bufferPointer: ptr), $0) }
    }

    // Frees the buffer in place.
    // The buffer must not be used after this is called.
    func deallocate() {
        try! rustCall { ffi_kube_viewer_54fe_rustbuffer_free(self, $0) }
    }
}

fileprivate extension ForeignBytes {
    init(bufferPointer: UnsafeBufferPointer<UInt8>) {
        self.init(len: Int32(bufferPointer.count), data: bufferPointer.baseAddress)
    }
}

// For every type used in the interface, we provide helper methods for conveniently
// lifting and lowering that type from C-compatible data, and for reading and writing
// values of that type in a buffer.

// Helper classes/extensions that don't change.
// Someday, this will be in a library of its own.

fileprivate extension Data {
    init(rustBuffer: RustBuffer) {
        // TODO: This copies the buffer. Can we read directly from a
        // Rust buffer?
        self.init(bytes: rustBuffer.data!, count: Int(rustBuffer.len))
    }
}

// Define reader functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.
//
// With external types, one swift source file needs to be able to call the read
// method on another source file's FfiConverter, but then what visibility
// should Reader have?
// - If Reader is fileprivate, then this means the read() must also
//   be fileprivate, which doesn't work with external types.
// - If Reader is internal/public, we'll get compile errors since both source
//   files will try define the same type.
//
// Instead, the read() method and these helper functions input a tuple of data

fileprivate func createReader(data: Data) -> (data: Data, offset: Data.Index) {
    (data: data, offset: 0)
}

// Reads an integer at the current offset, in big-endian order, and advances
// the offset on success. Throws if reading the integer would move the
// offset past the end of the buffer.
fileprivate func readInt<T: FixedWidthInteger>(_ reader: inout (data: Data, offset: Data.Index)) throws -> T {
    let range = reader.offset..<reader.offset + MemoryLayout<T>.size
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    if T.self == UInt8.self {
        let value = reader.data[reader.offset]
        reader.offset += 1
        return value as! T
    }
    var value: T = 0
    let _ = withUnsafeMutableBytes(of: &value, { reader.data.copyBytes(to: $0, from: range)})
    reader.offset = range.upperBound
    return value.bigEndian
}

// Reads an arbitrary number of bytes, to be used to read
// raw bytes, this is useful when lifting strings
fileprivate func readBytes(_ reader: inout (data: Data, offset: Data.Index), count: Int) throws -> Array<UInt8> {
    let range = reader.offset..<(reader.offset+count)
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    var value = [UInt8](repeating: 0, count: count)
    value.withUnsafeMutableBufferPointer({ buffer in
        reader.data.copyBytes(to: buffer, from: range)
    })
    reader.offset = range.upperBound
    return value
}

// Reads a float at the current offset.
fileprivate func readFloat(_ reader: inout (data: Data, offset: Data.Index)) throws -> Float {
    return Float(bitPattern: try readInt(&reader))
}

// Reads a float at the current offset.
fileprivate func readDouble(_ reader: inout (data: Data, offset: Data.Index)) throws -> Double {
    return Double(bitPattern: try readInt(&reader))
}

// Indicates if the offset has reached the end of the buffer.
fileprivate func hasRemaining(_ reader: (data: Data, offset: Data.Index)) -> Bool {
    return reader.offset < reader.data.count
}

// Define writer functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.  See the above discussion on Readers for details.

fileprivate func createWriter() -> [UInt8] {
    return []
}

fileprivate func writeBytes<S>(_ writer: inout [UInt8], _ byteArr: S) where S: Sequence, S.Element == UInt8 {
    writer.append(contentsOf: byteArr)
}

// Writes an integer in big-endian order.
//
// Warning: make sure what you are trying to write
// is in the correct type!
fileprivate func writeInt<T: FixedWidthInteger>(_ writer: inout [UInt8], _ value: T) {
    var value = value.bigEndian
    withUnsafeBytes(of: &value) { writer.append(contentsOf: $0) }
}

fileprivate func writeFloat(_ writer: inout [UInt8], _ value: Float) {
    writeInt(&writer, value.bitPattern)
}

fileprivate func writeDouble(_ writer: inout [UInt8], _ value: Double) {
    writeInt(&writer, value.bitPattern)
}

// Protocol for types that transfer other types across the FFI. This is
// analogous go the Rust trait of the same name.
fileprivate protocol FfiConverter {
    associatedtype FfiType
    associatedtype SwiftType

    static func lift(_ value: FfiType) throws -> SwiftType
    static func lower(_ value: SwiftType) -> FfiType
    static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> SwiftType
    static func write(_ value: SwiftType, into buf: inout [UInt8])
}

// Types conforming to `Primitive` pass themselves directly over the FFI.
fileprivate protocol FfiConverterPrimitive: FfiConverter where FfiType == SwiftType { }

extension FfiConverterPrimitive {
    public static func lift(_ value: FfiType) throws -> SwiftType {
        return value
    }

    public static func lower(_ value: SwiftType) -> FfiType {
        return value
    }
}

// Types conforming to `FfiConverterRustBuffer` lift and lower into a `RustBuffer`.
// Used for complex types where it's hard to write a custom lift/lower.
fileprivate protocol FfiConverterRustBuffer: FfiConverter where FfiType == RustBuffer {}

extension FfiConverterRustBuffer {
    public static func lift(_ buf: RustBuffer) throws -> SwiftType {
        var reader = createReader(data: Data(rustBuffer: buf))
        let value = try read(from: &reader)
        if hasRemaining(reader) {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }

    public static func lower(_ value: SwiftType) -> RustBuffer {
          var writer = createWriter()
          write(value, into: &writer)
          return RustBuffer(bytes: writer)
    }
}
// An error type for FFI errors. These errors occur at the UniFFI level, not
// the library level.
fileprivate enum UniffiInternalError: LocalizedError {
    case bufferOverflow
    case incompleteData
    case unexpectedOptionalTag
    case unexpectedEnumCase
    case unexpectedNullPointer
    case unexpectedRustCallStatusCode
    case unexpectedRustCallError
    case unexpectedStaleHandle
    case rustPanic(_ message: String)

    public var errorDescription: String? {
        switch self {
        case .bufferOverflow: return "Reading the requested value would read past the end of the buffer"
        case .incompleteData: return "The buffer still has data after lifting its containing value"
        case .unexpectedOptionalTag: return "Unexpected optional tag; should be 0 or 1"
        case .unexpectedEnumCase: return "Raw enum value doesn't match any cases"
        case .unexpectedNullPointer: return "Raw pointer value was null"
        case .unexpectedRustCallStatusCode: return "Unexpected RustCallStatus code"
        case .unexpectedRustCallError: return "CALL_ERROR but no errorClass specified"
        case .unexpectedStaleHandle: return "The object in the handle map has been dropped already"
        case let .rustPanic(message): return message
        }
    }
}

fileprivate let CALL_SUCCESS: Int8 = 0
fileprivate let CALL_ERROR: Int8 = 1
fileprivate let CALL_PANIC: Int8 = 2

fileprivate extension RustCallStatus {
    init() {
        self.init(
            code: CALL_SUCCESS,
            errorBuf: RustBuffer.init(
                capacity: 0,
                len: 0,
                data: nil
            )
        )
    }
}

private func rustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    try makeRustCall(callback, errorHandler: {
        $0.deallocate()
        return UniffiInternalError.unexpectedRustCallError
    })
}

private func rustCallWithError<T, F: FfiConverter>
    (_ errorFfiConverter: F.Type, _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T
    where F.SwiftType: Error, F.FfiType == RustBuffer
    {
    try makeRustCall(callback, errorHandler: { return try errorFfiConverter.lift($0) })
}

private func makeRustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T, errorHandler: (RustBuffer) throws -> Error) throws -> T {
    var callStatus = RustCallStatus.init()
    let returnedVal = callback(&callStatus)
    switch callStatus.code {
        case CALL_SUCCESS:
            return returnedVal

        case CALL_ERROR:
            throw try errorHandler(callStatus.errorBuf)

        case CALL_PANIC:
            // When the rust code sees a panic, it tries to construct a RustBuffer
            // with the message.  But if that code panics, then it just sends back
            // an empty buffer.
            if callStatus.errorBuf.len > 0 {
                throw UniffiInternalError.rustPanic(try FfiConverterString.lift(callStatus.errorBuf))
            } else {
                callStatus.errorBuf.deallocate()
                throw UniffiInternalError.rustPanic("Rust panic")
            }

        default:
            throw UniffiInternalError.unexpectedRustCallStatusCode
    }
}

// Public interface members begin here.


fileprivate struct FfiConverterBool : FfiConverter {
    typealias FfiType = Int8
    typealias SwiftType = Bool

    public static func lift(_ value: Int8) throws -> Bool {
        return value != 0
    }

    public static func lower(_ value: Bool) -> Int8 {
        return value ? 1 : 0
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Bool {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: Bool, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

fileprivate struct FfiConverterString: FfiConverter {
    typealias SwiftType = String
    typealias FfiType = RustBuffer

    public static func lift(_ value: RustBuffer) throws -> String {
        defer {
            value.deallocate()
        }
        if value.data == nil {
            return String()
        }
        let bytes = UnsafeBufferPointer<UInt8>(start: value.data!, count: Int(value.len))
        return String(bytes: bytes, encoding: String.Encoding.utf8)!
    }

    public static func lower(_ value: String) -> RustBuffer {
        return value.utf8CString.withUnsafeBufferPointer { ptr in
            // The swift string gives us int8_t, we want uint8_t.
            ptr.withMemoryRebound(to: UInt8.self) { ptr in
                // The swift string gives us a trailing null byte, we don't want it.
                let buf = UnsafeBufferPointer(rebasing: ptr.prefix(upTo: ptr.count - 1))
                return RustBuffer.from(buf)
            }
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> String {
        let len: Int32 = try readInt(&buf)
        return String(bytes: try readBytes(&buf, count: Int(len)), encoding: String.Encoding.utf8)!
    }

    public static func write(_ value: String, into buf: inout [UInt8]) {
        let len = Int32(value.utf8.count)
        writeInt(&buf, len)
        writeBytes(&buf, value.utf8)
    }
}


public protocol RustMainViewModelProtocol {
    func `currentFocusRegion`()  -> FocusRegion
    func `handleKeyInput`(`keyInput`: KeyAwareEvent)  -> Bool
    func `selectedTab`()  -> TabId
    func `setCurrentFocusRegion`(`currentFocusRegion`: FocusRegion) 
    func `setSelectedTab`(`selectedTab`: TabId) 
    func `setTabGroupExpansions`(`tabGroupExpansions`: [TabGroupId: Bool]) 
    func `tabGroupExpansions`()  -> [TabGroupId: Bool]
    func `tabGroups`()  -> [TabGroup]
    func `tabGroupsFiltered`(`search`: String)  -> [TabGroup]
    func `tabs`()  -> [Tab]
    func `tabsMap`()  -> [TabId: Tab]
    
}

public class RustMainViewModel: RustMainViewModelProtocol {
    fileprivate let pointer: UnsafeMutableRawPointer

    // TODO: We'd like this to be `private` but for Swifty reasons,
    // we can't implement `FfiConverter` without making this `required` and we can't
    // make it `required` without making it `public`.
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        self.pointer = pointer
    }
    public convenience init()  {
        self.init(unsafeFromRawPointer: try!
    
    rustCall() {
    
    kube_viewer_54fe_RustMainViewModel_new($0)
})
    }

    deinit {
        try! rustCall { ffi_kube_viewer_54fe_RustMainViewModel_object_free(pointer, $0) }
    }

    

    
    public func `currentFocusRegion`()  -> FocusRegion {
        return try! FfiConverterTypeFocusRegion.lift(
            try!
    rustCall() {
    
    _uniffi_kube_viewer_impl_RustMainViewModel_current_focus_region_447f(self.pointer, $0
    )
}
        )
    }
    public func `handleKeyInput`(`keyInput`: KeyAwareEvent)  -> Bool {
        return try! FfiConverterBool.lift(
            try!
    rustCall() {
    
    _uniffi_kube_viewer_impl_RustMainViewModel_handle_key_input_81e8(self.pointer, 
        FfiConverterTypeKeyAwareEvent.lower(`keyInput`), $0
    )
}
        )
    }
    public func `selectedTab`()  -> TabId {
        return try! FfiConverterTypeTabId.lift(
            try!
    rustCall() {
    
    _uniffi_kube_viewer_impl_RustMainViewModel_selected_tab_9ae(self.pointer, $0
    )
}
        )
    }
    public func `setCurrentFocusRegion`(`currentFocusRegion`: FocusRegion)  {
        try!
    rustCall() {
    
    _uniffi_kube_viewer_impl_RustMainViewModel_set_current_focus_region_46b(self.pointer, 
        FfiConverterTypeFocusRegion.lower(`currentFocusRegion`), $0
    )
}
    }
    public func `setSelectedTab`(`selectedTab`: TabId)  {
        try!
    rustCall() {
    
    _uniffi_kube_viewer_impl_RustMainViewModel_set_selected_tab_48a9(self.pointer, 
        FfiConverterTypeTabId.lower(`selectedTab`), $0
    )
}
    }
    public func `setTabGroupExpansions`(`tabGroupExpansions`: [TabGroupId: Bool])  {
        try!
    rustCall() {
    
    _uniffi_kube_viewer_impl_RustMainViewModel_set_tab_group_expansions_ac8c(self.pointer, 
        FfiConverterDictionaryTypeTabGroupIdBool.lower(`tabGroupExpansions`), $0
    )
}
    }
    public func `tabGroupExpansions`()  -> [TabGroupId: Bool] {
        return try! FfiConverterDictionaryTypeTabGroupIdBool.lift(
            try!
    rustCall() {
    
    _uniffi_kube_viewer_impl_RustMainViewModel_tab_group_expansions_8bbf(self.pointer, $0
    )
}
        )
    }
    public func `tabGroups`()  -> [TabGroup] {
        return try! FfiConverterSequenceTypeTabGroup.lift(
            try!
    rustCall() {
    
    _uniffi_kube_viewer_impl_RustMainViewModel_tab_groups_f31a(self.pointer, $0
    )
}
        )
    }
    public func `tabGroupsFiltered`(`search`: String)  -> [TabGroup] {
        return try! FfiConverterSequenceTypeTabGroup.lift(
            try!
    rustCall() {
    
    _uniffi_kube_viewer_impl_RustMainViewModel_tab_groups_filtered_4d4b(self.pointer, 
        FfiConverterString.lower(`search`), $0
    )
}
        )
    }
    public func `tabs`()  -> [Tab] {
        return try! FfiConverterSequenceTypeTab.lift(
            try!
    rustCall() {
    
    _uniffi_kube_viewer_impl_RustMainViewModel_tabs_57ab(self.pointer, $0
    )
}
        )
    }
    public func `tabsMap`()  -> [TabId: Tab] {
        return try! FfiConverterDictionaryTypeTabIdTypeTab.lift(
            try!
    rustCall() {
    
    _uniffi_kube_viewer_impl_RustMainViewModel_tabs_map_4669(self.pointer, $0
    )
}
        )
    }
    
}


public struct FfiConverterTypeRustMainViewModel: FfiConverter {
    typealias FfiType = UnsafeMutableRawPointer
    typealias SwiftType = RustMainViewModel

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> RustMainViewModel {
        let v: UInt64 = try readInt(&buf)
        // The Rust code won't compile if a pointer won't fit in a UInt64.
        // We have to go via `UInt` because that's the thing that's the size of a pointer.
        let ptr = UnsafeMutableRawPointer(bitPattern: UInt(truncatingIfNeeded: v))
        if (ptr == nil) {
            throw UniffiInternalError.unexpectedNullPointer
        }
        return try lift(ptr!)
    }

    public static func write(_ value: RustMainViewModel, into buf: inout [UInt8]) {
        // This fiddling is because `Int` is the thing that's the same size as a pointer.
        // The Rust code won't compile if a pointer won't fit in a `UInt64`.
        writeInt(&buf, UInt64(bitPattern: Int64(Int(bitPattern: lower(value)))))
    }

    public static func lift(_ pointer: UnsafeMutableRawPointer) throws -> RustMainViewModel {
        return RustMainViewModel(unsafeFromRawPointer: pointer)
    }

    public static func lower(_ value: RustMainViewModel) -> UnsafeMutableRawPointer {
        return value.pointer
    }
}


public struct Tab {
    public var `id`: TabId
    public var `icon`: String
    public var `name`: String

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(`id`: TabId, `icon`: String, `name`: String) {
        self.`id` = `id`
        self.`icon` = `icon`
        self.`name` = `name`
    }
}


extension Tab: Equatable, Hashable {
    public static func ==(lhs: Tab, rhs: Tab) -> Bool {
        if lhs.`id` != rhs.`id` {
            return false
        }
        if lhs.`icon` != rhs.`icon` {
            return false
        }
        if lhs.`name` != rhs.`name` {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(`id`)
        hasher.combine(`icon`)
        hasher.combine(`name`)
    }
}


public struct FfiConverterTypeTab: FfiConverterRustBuffer {
    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Tab {
        return try Tab(
            `id`: FfiConverterTypeTabId.read(from: &buf), 
            `icon`: FfiConverterString.read(from: &buf), 
            `name`: FfiConverterString.read(from: &buf)
        )
    }

    public static func write(_ value: Tab, into buf: inout [UInt8]) {
        FfiConverterTypeTabId.write(value.`id`, into: &buf)
        FfiConverterString.write(value.`icon`, into: &buf)
        FfiConverterString.write(value.`name`, into: &buf)
    }
}


public func FfiConverterTypeTab_lift(_ buf: RustBuffer) throws -> Tab {
    return try FfiConverterTypeTab.lift(buf)
}

public func FfiConverterTypeTab_lower(_ value: Tab) -> RustBuffer {
    return FfiConverterTypeTab.lower(value)
}


public struct TabGroup {
    public var `id`: TabGroupId
    public var `name`: String
    public var `tabs`: [Tab]

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(`id`: TabGroupId, `name`: String, `tabs`: [Tab]) {
        self.`id` = `id`
        self.`name` = `name`
        self.`tabs` = `tabs`
    }
}


extension TabGroup: Equatable, Hashable {
    public static func ==(lhs: TabGroup, rhs: TabGroup) -> Bool {
        if lhs.`id` != rhs.`id` {
            return false
        }
        if lhs.`name` != rhs.`name` {
            return false
        }
        if lhs.`tabs` != rhs.`tabs` {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(`id`)
        hasher.combine(`name`)
        hasher.combine(`tabs`)
    }
}


public struct FfiConverterTypeTabGroup: FfiConverterRustBuffer {
    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> TabGroup {
        return try TabGroup(
            `id`: FfiConverterTypeTabGroupId.read(from: &buf), 
            `name`: FfiConverterString.read(from: &buf), 
            `tabs`: FfiConverterSequenceTypeTab.read(from: &buf)
        )
    }

    public static func write(_ value: TabGroup, into buf: inout [UInt8]) {
        FfiConverterTypeTabGroupId.write(value.`id`, into: &buf)
        FfiConverterString.write(value.`name`, into: &buf)
        FfiConverterSequenceTypeTab.write(value.`tabs`, into: &buf)
    }
}


public func FfiConverterTypeTabGroup_lift(_ buf: RustBuffer) throws -> TabGroup {
    return try FfiConverterTypeTabGroup.lift(buf)
}

public func FfiConverterTypeTabGroup_lower(_ value: TabGroup) -> RustBuffer {
    return FfiConverterTypeTabGroup.lower(value)
}

// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.
public enum FocusRegion {
    
    case `sidebarSearch`
    case `sidebar`
    case `sidebarGroup`(`id`: TabGroupId)
    case `clusterSelection`
    case `content`
}

public struct FfiConverterTypeFocusRegion: FfiConverterRustBuffer {
    typealias SwiftType = FocusRegion

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> FocusRegion {
        let variant: Int32 = try readInt(&buf)
        switch variant {
        
        case 1: return .`sidebarSearch`
        
        case 2: return .`sidebar`
        
        case 3: return .`sidebarGroup`(
            `id`: try FfiConverterTypeTabGroupId.read(from: &buf)
        )
        
        case 4: return .`clusterSelection`
        
        case 5: return .`content`
        
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: FocusRegion, into buf: inout [UInt8]) {
        switch value {
        
        
        case .`sidebarSearch`:
            writeInt(&buf, Int32(1))
        
        
        case .`sidebar`:
            writeInt(&buf, Int32(2))
        
        
        case let .`sidebarGroup`(`id`):
            writeInt(&buf, Int32(3))
            FfiConverterTypeTabGroupId.write(`id`, into: &buf)
            
        
        case .`clusterSelection`:
            writeInt(&buf, Int32(4))
        
        
        case .`content`:
            writeInt(&buf, Int32(5))
        
        }
    }
}


public func FfiConverterTypeFocusRegion_lift(_ buf: RustBuffer) throws -> FocusRegion {
    return try FfiConverterTypeFocusRegion.lift(buf)
}

public func FfiConverterTypeFocusRegion_lower(_ value: FocusRegion) -> RustBuffer {
    return FfiConverterTypeFocusRegion.lower(value)
}


extension FocusRegion: Equatable, Hashable {}


// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.
public enum KeyAwareEvent {
    
    case `delete`
    case `upArrow`
    case `downArrow`
    case `leftArrow`
    case `rightArrow`
    case `space`
    case `enter`
    case `shiftTab`
    case `tabKey`
}

public struct FfiConverterTypeKeyAwareEvent: FfiConverterRustBuffer {
    typealias SwiftType = KeyAwareEvent

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> KeyAwareEvent {
        let variant: Int32 = try readInt(&buf)
        switch variant {
        
        case 1: return .`delete`
        
        case 2: return .`upArrow`
        
        case 3: return .`downArrow`
        
        case 4: return .`leftArrow`
        
        case 5: return .`rightArrow`
        
        case 6: return .`space`
        
        case 7: return .`enter`
        
        case 8: return .`shiftTab`
        
        case 9: return .`tabKey`
        
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: KeyAwareEvent, into buf: inout [UInt8]) {
        switch value {
        
        
        case .`delete`:
            writeInt(&buf, Int32(1))
        
        
        case .`upArrow`:
            writeInt(&buf, Int32(2))
        
        
        case .`downArrow`:
            writeInt(&buf, Int32(3))
        
        
        case .`leftArrow`:
            writeInt(&buf, Int32(4))
        
        
        case .`rightArrow`:
            writeInt(&buf, Int32(5))
        
        
        case .`space`:
            writeInt(&buf, Int32(6))
        
        
        case .`enter`:
            writeInt(&buf, Int32(7))
        
        
        case .`shiftTab`:
            writeInt(&buf, Int32(8))
        
        
        case .`tabKey`:
            writeInt(&buf, Int32(9))
        
        }
    }
}


public func FfiConverterTypeKeyAwareEvent_lift(_ buf: RustBuffer) throws -> KeyAwareEvent {
    return try FfiConverterTypeKeyAwareEvent.lift(buf)
}

public func FfiConverterTypeKeyAwareEvent_lower(_ value: KeyAwareEvent) -> RustBuffer {
    return FfiConverterTypeKeyAwareEvent.lower(value)
}


extension KeyAwareEvent: Equatable, Hashable {}


// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.
public enum TabGroupId {
    
    case `general`
    case `workloads`
    case `config`
    case `network`
    case `storage`
    case `accessControl`
    case `helm`
}

public struct FfiConverterTypeTabGroupId: FfiConverterRustBuffer {
    typealias SwiftType = TabGroupId

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> TabGroupId {
        let variant: Int32 = try readInt(&buf)
        switch variant {
        
        case 1: return .`general`
        
        case 2: return .`workloads`
        
        case 3: return .`config`
        
        case 4: return .`network`
        
        case 5: return .`storage`
        
        case 6: return .`accessControl`
        
        case 7: return .`helm`
        
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: TabGroupId, into buf: inout [UInt8]) {
        switch value {
        
        
        case .`general`:
            writeInt(&buf, Int32(1))
        
        
        case .`workloads`:
            writeInt(&buf, Int32(2))
        
        
        case .`config`:
            writeInt(&buf, Int32(3))
        
        
        case .`network`:
            writeInt(&buf, Int32(4))
        
        
        case .`storage`:
            writeInt(&buf, Int32(5))
        
        
        case .`accessControl`:
            writeInt(&buf, Int32(6))
        
        
        case .`helm`:
            writeInt(&buf, Int32(7))
        
        }
    }
}


public func FfiConverterTypeTabGroupId_lift(_ buf: RustBuffer) throws -> TabGroupId {
    return try FfiConverterTypeTabGroupId.lift(buf)
}

public func FfiConverterTypeTabGroupId_lower(_ value: TabGroupId) -> RustBuffer {
    return FfiConverterTypeTabGroupId.lower(value)
}


extension TabGroupId: Equatable, Hashable {}


// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.
public enum TabId {
    
    case `cluster`
    case `nodes`
    case `nameSpaces`
    case `events`
    case `overview`
    case `pods`
    case `deployments`
    case `daemonSets`
    case `statefulSets`
    case `replicaSets`
    case `jobs`
    case `cronJobs`
    case `configMaps`
    case `secrets`
    case `resourceQuotas`
    case `limitRanges`
    case `horizontalPodAutoscalers`
    case `podDisruptionBudgets`
    case `priorityClasses`
    case `runtimeClasses`
    case `leases`
    case `services`
    case `endpoints`
    case `ingresses`
    case `networkPolicies`
    case `portForwarding`
    case `persistentVolumeClaims`
    case `persistentVolumes`
    case `storageClasses`
    case `serviceAccounts`
    case `clusterRoles`
    case `roles`
    case `clusterRoleBindings`
    case `roleBindings`
    case `podSecurityPolicies`
    case `charts`
    case `releases`
}

public struct FfiConverterTypeTabId: FfiConverterRustBuffer {
    typealias SwiftType = TabId

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> TabId {
        let variant: Int32 = try readInt(&buf)
        switch variant {
        
        case 1: return .`cluster`
        
        case 2: return .`nodes`
        
        case 3: return .`nameSpaces`
        
        case 4: return .`events`
        
        case 5: return .`overview`
        
        case 6: return .`pods`
        
        case 7: return .`deployments`
        
        case 8: return .`daemonSets`
        
        case 9: return .`statefulSets`
        
        case 10: return .`replicaSets`
        
        case 11: return .`jobs`
        
        case 12: return .`cronJobs`
        
        case 13: return .`configMaps`
        
        case 14: return .`secrets`
        
        case 15: return .`resourceQuotas`
        
        case 16: return .`limitRanges`
        
        case 17: return .`horizontalPodAutoscalers`
        
        case 18: return .`podDisruptionBudgets`
        
        case 19: return .`priorityClasses`
        
        case 20: return .`runtimeClasses`
        
        case 21: return .`leases`
        
        case 22: return .`services`
        
        case 23: return .`endpoints`
        
        case 24: return .`ingresses`
        
        case 25: return .`networkPolicies`
        
        case 26: return .`portForwarding`
        
        case 27: return .`persistentVolumeClaims`
        
        case 28: return .`persistentVolumes`
        
        case 29: return .`storageClasses`
        
        case 30: return .`serviceAccounts`
        
        case 31: return .`clusterRoles`
        
        case 32: return .`roles`
        
        case 33: return .`clusterRoleBindings`
        
        case 34: return .`roleBindings`
        
        case 35: return .`podSecurityPolicies`
        
        case 36: return .`charts`
        
        case 37: return .`releases`
        
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: TabId, into buf: inout [UInt8]) {
        switch value {
        
        
        case .`cluster`:
            writeInt(&buf, Int32(1))
        
        
        case .`nodes`:
            writeInt(&buf, Int32(2))
        
        
        case .`nameSpaces`:
            writeInt(&buf, Int32(3))
        
        
        case .`events`:
            writeInt(&buf, Int32(4))
        
        
        case .`overview`:
            writeInt(&buf, Int32(5))
        
        
        case .`pods`:
            writeInt(&buf, Int32(6))
        
        
        case .`deployments`:
            writeInt(&buf, Int32(7))
        
        
        case .`daemonSets`:
            writeInt(&buf, Int32(8))
        
        
        case .`statefulSets`:
            writeInt(&buf, Int32(9))
        
        
        case .`replicaSets`:
            writeInt(&buf, Int32(10))
        
        
        case .`jobs`:
            writeInt(&buf, Int32(11))
        
        
        case .`cronJobs`:
            writeInt(&buf, Int32(12))
        
        
        case .`configMaps`:
            writeInt(&buf, Int32(13))
        
        
        case .`secrets`:
            writeInt(&buf, Int32(14))
        
        
        case .`resourceQuotas`:
            writeInt(&buf, Int32(15))
        
        
        case .`limitRanges`:
            writeInt(&buf, Int32(16))
        
        
        case .`horizontalPodAutoscalers`:
            writeInt(&buf, Int32(17))
        
        
        case .`podDisruptionBudgets`:
            writeInt(&buf, Int32(18))
        
        
        case .`priorityClasses`:
            writeInt(&buf, Int32(19))
        
        
        case .`runtimeClasses`:
            writeInt(&buf, Int32(20))
        
        
        case .`leases`:
            writeInt(&buf, Int32(21))
        
        
        case .`services`:
            writeInt(&buf, Int32(22))
        
        
        case .`endpoints`:
            writeInt(&buf, Int32(23))
        
        
        case .`ingresses`:
            writeInt(&buf, Int32(24))
        
        
        case .`networkPolicies`:
            writeInt(&buf, Int32(25))
        
        
        case .`portForwarding`:
            writeInt(&buf, Int32(26))
        
        
        case .`persistentVolumeClaims`:
            writeInt(&buf, Int32(27))
        
        
        case .`persistentVolumes`:
            writeInt(&buf, Int32(28))
        
        
        case .`storageClasses`:
            writeInt(&buf, Int32(29))
        
        
        case .`serviceAccounts`:
            writeInt(&buf, Int32(30))
        
        
        case .`clusterRoles`:
            writeInt(&buf, Int32(31))
        
        
        case .`roles`:
            writeInt(&buf, Int32(32))
        
        
        case .`clusterRoleBindings`:
            writeInt(&buf, Int32(33))
        
        
        case .`roleBindings`:
            writeInt(&buf, Int32(34))
        
        
        case .`podSecurityPolicies`:
            writeInt(&buf, Int32(35))
        
        
        case .`charts`:
            writeInt(&buf, Int32(36))
        
        
        case .`releases`:
            writeInt(&buf, Int32(37))
        
        }
    }
}


public func FfiConverterTypeTabId_lift(_ buf: RustBuffer) throws -> TabId {
    return try FfiConverterTypeTabId.lift(buf)
}

public func FfiConverterTypeTabId_lower(_ value: TabId) -> RustBuffer {
    return FfiConverterTypeTabId.lower(value)
}


extension TabId: Equatable, Hashable {}


fileprivate struct FfiConverterSequenceTypeTab: FfiConverterRustBuffer {
    typealias SwiftType = [Tab]

    public static func write(_ value: [Tab], into buf: inout [UInt8]) {
        let len = Int32(value.count)
        writeInt(&buf, len)
        for item in value {
            FfiConverterTypeTab.write(item, into: &buf)
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> [Tab] {
        let len: Int32 = try readInt(&buf)
        var seq = [Tab]()
        seq.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            seq.append(try FfiConverterTypeTab.read(from: &buf))
        }
        return seq
    }
}

fileprivate struct FfiConverterSequenceTypeTabGroup: FfiConverterRustBuffer {
    typealias SwiftType = [TabGroup]

    public static func write(_ value: [TabGroup], into buf: inout [UInt8]) {
        let len = Int32(value.count)
        writeInt(&buf, len)
        for item in value {
            FfiConverterTypeTabGroup.write(item, into: &buf)
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> [TabGroup] {
        let len: Int32 = try readInt(&buf)
        var seq = [TabGroup]()
        seq.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            seq.append(try FfiConverterTypeTabGroup.read(from: &buf))
        }
        return seq
    }
}

fileprivate struct FfiConverterDictionaryTypeTabGroupIdBool: FfiConverterRustBuffer {
    public static func write(_ value: [TabGroupId: Bool], into buf: inout [UInt8]) {
        let len = Int32(value.count)
        writeInt(&buf, len)
        for (key, value) in value {
            FfiConverterTypeTabGroupId.write(key, into: &buf)
            FfiConverterBool.write(value, into: &buf)
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> [TabGroupId: Bool] {
        let len: Int32 = try readInt(&buf)
        var dict = [TabGroupId: Bool]()
        dict.reserveCapacity(Int(len))
        for _ in 0..<len {
            let key = try FfiConverterTypeTabGroupId.read(from: &buf)
            let value = try FfiConverterBool.read(from: &buf)
            dict[key] = value
        }
        return dict
    }
}

fileprivate struct FfiConverterDictionaryTypeTabIdTypeTab: FfiConverterRustBuffer {
    public static func write(_ value: [TabId: Tab], into buf: inout [UInt8]) {
        let len = Int32(value.count)
        writeInt(&buf, len)
        for (key, value) in value {
            FfiConverterTypeTabId.write(key, into: &buf)
            FfiConverterTypeTab.write(value, into: &buf)
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> [TabId: Tab] {
        let len: Int32 = try readInt(&buf)
        var dict = [TabId: Tab]()
        dict.reserveCapacity(Int(len))
        for _ in 0..<len {
            let key = try FfiConverterTypeTabId.read(from: &buf)
            let value = try FfiConverterTypeTab.read(from: &buf)
            dict[key] = value
        }
        return dict
    }
}

/**
 * Top level initializers and tear down methods.
 *
 * This is generated by uniffi.
 */
public enum KubeViewerLifecycle {
    /**
     * Initialize the FFI and Rust library. This should be only called once per application.
     */
    func initialize() {
    }
}