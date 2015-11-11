# YSMessagePack- for swift 2.1

YSMessagePack is a messagePack packer/unpacker written in swift 2.1. It is designed to be light and easy to use. YSMessagePack include following features:

- Pack and unpack multiple message-packed data regardless of types with only one line of code
- Specify how many items to unpack
- Packing options
- Get remaining bytes that were not message-packed
- Helper methods to cast NSData to desired types

## Version
beta - 0.1

## Installation

Simply add files under the directory below to your project                                                                                                                                                                                                                                                                  
```url
MessagePack/src
```

# Usage 
### Pack:

```swift
let exampleInt: Int = 1
let exampleStr: String = "Hello World"
let exampleArray: [Int] = [1, 2, 3, 4, 5, 6]

//use the method `packItems' to pack 
//this will be the packed data
let msgPackedBytes: NSData = packItems([exampleInt, exampleStr, exampleArray]) 
```

**Or you can pack them individually and add them to a byte array manually (Which is also less expensive)**

```swift
let exampleInt: Int = 1
let exampleStr: String = "Hello World"
let exampleArray: [Int] = [1, 2, 3, 4, 5, 6]

//Now pack them idividually
let packedInt = exampleInt.pack()

//if you didn't specifiy encoding, the default encoding will be ASCII
let packedStr = exampleStr.pack(withEncoding: NSASCIIStringEncoding) 

let packedArray = exampleArray.pack()
let msgPackedBytes: NSData = packedInt.byte_array + packedStr.byte_array + packedArray.byte_array
```
## Unpack
Unpack a messagePacked byte array is also very easy:

```swift
do {
    //The unpack method will return an array of NSData which each element is an unpacked object
    let unpackedItems = try msgPackedBytes.unpack()
    //instead of casting the NSData to the type you want, you can call these `.castTo..` methods to do the job for you
    let int: Int = unpackedItems[0].castToInt()

    //Same as packing, you can also specify the encoding you want to use, default is ASCII
    let str: String = unpackedItems[1].castToString() 
    let array: NSArray = unpackedItems[2].castToArray() 
} catch let error as NSError{
    NSLog("Error occurs during unpacking: %@", error)
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


