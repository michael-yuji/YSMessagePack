# YSMessagePack- for swift 3

YSMessagePack is a messagePack packer/unpacker written in swift (swift 3 ready). It is designed to be light and easy to use. YSMessagePack include following features:

- (new) Pack custom structs and classes
- Pack and unpack multiple message-packed data regardless of types with only one line of code
- Specify how many items to unpack
- Packing options
- Get remaining bytes that were not message-packed
- Helper methods to cast NSData to desired types

## Version
 1.1

## Installation

Simply add files under the directory below to your project

                                                                                   `


```url
MessagePack/src
```


# Usage 
### Pack:



```swift
struct MyStruct: Packable {  //Confirm to this protocol
    var name: String
    var index: Int
    func packFormat() -> [AnyObject] { //protocol function
        return [name, index] //pack order
    }
}

let exampleInt: Int = 1
let exampleStr: String = "Hello World"
let exampleArray: [Int] = [1, 2, 3, 4, 5, 6]
let bool: Bool = true
let foo = MyStruct(name: "foo", index: 626)

//use the method `packItems` to pack 
//For primitive types (and boolean) or your custom type, use `Mask(foo)` in the array
//this will be the packed data
let msgPackedBytes: NSData = packItems([Mask(foo), Mask(foo), exampleInt, exampleStr, exampleArray]) 
```

**Or you can pack them individually and add them to a byte array manually (Which is also less expensive)**

```swift
let exampleInt: Int = 1
let exampleStr: String = "Hello World"
let exampleArray: [Int] = [1, 2, 3, 4, 5, 6]

//Now pack them individually
let packedInt = exampleInt.pack()

//if you didn't specific encoding, the default encoding will be ASCII
let packedStr = exampleStr.pack(withEncoding: NSASCIIStringEncoding) 

let packedArray = exampleArray.pack()
//You can use this operator +^ the join the data on rhs to the end of data on lhs
let msgPackedBytes: NSData = packedInt +^ packedStr +^ packedArray
```
## Unpack
Unpack a messagePacked byte array is also very easy:

```swift
do {
    //The unpack method will return an array of NSData which each element is an unpacked object
    let unpackedItems = try msgPackedBytes.unpack()
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
    let unpackedItems = try msgPackedBytes.unpack(specific_amount: 2, returnRemainingBytes: false)
    print(unpackedItems.count) //will print 2
} catch let error as NSError{
    NSLog("Error occurs during unpacking: %@", error)
}
```


