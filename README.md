# YSMessagePack- for swift 3

YSMessagePack is a messagePack packer/unpacker written in swift (swift 3 ready). It is designed to be easy to use. YSMessagePack include following features:

- Pack custom structs and classes / unpack objects by groups and apply handler to each group (easier to re-construct your struct$)
- Asynchronous unpacking
- Pack and unpack multiple message-packed data regardless of types with only one line of code
- Specify how many items to unpack
- Get remaining bytes that were not message-packed ; start packing from some index -- so you can mix messagepack with other protocol!!! 
- Helper methods to cast NSData to desired types
- Operator +^ and +^= to join NSData 


## Version
 1.6.2 (Dropped swift 2 support, swift 3 support only from now on)

## Installation

- Simply add files under `YSMessagePack/Classes` to your project, 
- use cocoapod, add "pod `'YSMessagePack', '~> 1.6.2'` to your podfile  

# Usage 
### Pack:



```swift

let exampleInt: Int = 1
let exampleStr: String = "Hello World"
let exampleArray: [Int] = [1, 2, 3, 4, 5, 6]
let bool: Bool = true

// To pack items, just put all of them in a single array
// and call the `pack(items:)` function

//this will be the packed data
let msgPackedBytes: NSData = pack(items: [true, foo, exampleInt, exampleStr, exampleArray]) 

// Now your payload is ready to send!!!

```

But what if we have some custom data structure to send?

```Swift

//To make your struct / class packable
struct MyStruct: Packable {  //Confirm to this protocol
    var name: String
    var index: Int
    func packFormat() -> [Packable] { //protocol function
        return [name, index] //pack order
    }
    
    func msgtype() -> MsgPackTypes {
        return .Custom
    }
}

let exampleInt: Int = 1
let exampleStr: String = "Hello World"
let exampleArray: [Int] = [1, 2, 3, 4, 5]
let bool: Bool = true

let foo = MyStruct(name: "foo", index: 626)

let msgPackedBytes = pack(items: [bool, foo, exampleInt, exampleStr, exampleArray])

```


**Or you can pack them individually and add them to a byte array manually (Which is also less expensive)**

```swift
let exampleInt: Int = 1
let exampleStr: String = "Hello World"
let exampleArray: [Int] = [1, 2, 3, 4, 5, 6]

//Now pack them individually
let packedInt = exampleInt.packed()

//if you didn't specific encoding, the default encoding will be ASCII
#if swift(>=3)
let packedStr = exampleStr.packed(withEncoding: NSASCIIStringEncoding) 
#else
let packedStr = exampleStr.packed(withEncoding: .ascii)
#endif
let packedArray = exampleArray.packed()
//You can use this operator +^ the join the data on rhs to the end of data on lhs
let msgPackedBytes: NSData = packedInt +^ packedStr +^ packedArray
```
## Unpack

YSMessagePack offer a number of different ways and options to unpack include unpack asynchronously, see the example project for detail.

To unpack a messagepacked bytearray is pretty easy:

```swift
do {
    //The unpack method will return an array of NSData which each element is an unpacked object
    let unpackedItems = try msgPackedBytes.itemsUnpacked()
    //instead of casting the NSData to the type you want, you can call these `.castTo..` methods to do the job for you
    let int: Int = unpackedItems[2].castToInt()

    //Same as packing, you can also specify the encoding you want to use, default is ASCII
    let str: String = unpackedItem[3].castToString() 
    let array: NSArray = unpackedItems[4].castToArray() 
} catch let error as NSError{
    NSLog("Error occurs during unpacking: %@", error)
}

//Remember how to pack your struct? Here is a better way to unpack a stream of bytes formatted in specific format
 let testObj1 = MyStruct(name: "TestObject1", index: 1)
 let testObj2 = MyStruct(name: "TestObject2", index: 2)
 let testObj3 = MyStruct(name: "TestObject3", index: 3)
 
 let packed = packCustomObjects(testObj1, testObj2, testObj3) //This is an other method that can pack your own struct easier
 
 let nobjsInOneGroup = 2
 
 try! packed.unpackByGroupsWith(nobjsInOneGroup) {
     (unpackedData, isLast) -> Bool
     
     //you can also involve additional args like number of groups to unpack
     guard let name = unpackedData[0].castToString() else {return false} //abort unpacking hen something wrong
     let index = unpackedData[1]
     let testObj = MyStruct(name: name, index: index) // assembly      
     return true //proceed unpacking, or return false to abort
 } 

```


**If you don't want to unpack every single thing included in the message-pack byte array, you can also specify an amount to unpack, if you want to keep the remaining bytes, you can put `true` in the `returnRemainingBytes` argument, the remaining bytes will stored in the end of the `NSData` array.**

```swift
do {
    //Unpack only 2 objects, and we are not interested in remaining bytes
    let unpackedItems = try msgPackedBytes.itemsUnpacked(specific_amount: 2, returnRemainingBytes: false)
    print(unpackedItems.count) //will print 2
} catch let error as NSError{
    NSLog("Error occurs during unpacking: %@", error)
}
```
