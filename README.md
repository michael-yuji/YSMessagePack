# YSMessagePack- for swift 3

YSMessagePack is a messagePack packer/unpacker written in swift (swift 3 ready). It is designed to be fast and easy to use. YSMessagePack include following features:

- (new) Pack custom structs and classes / unpack objects by groups and apply handler to each group (easier to re-construct your struct)
- Pack and unpack multiple message-packed data regardless of types with only one line of code
- Specify how many items to unpack
- Get remaining bytes that were not message-packed ; start packing from some index -- so you can mix messagepack with other protocol!!! 
- Helper methods to cast NSData to desired types
- Operator +^ and +^= to join NSData 
- Packing options
- For previous users: `Mask` class is no longer needed to wrap nil, uint, and custom types

## Version
 1.5

## Installation

Simply add files under the directory below to your project
                                                                                  

```url
MessagePack/src
```


# Usage 
### Pack:



```swift
//use the method `packItems` to pack 
//this will be the packed NSData
let packed = packItems(["abcde", 123123, 12323.24234, true, false])

let unpacks = try! packed.unpack()

print(unpacks[0].castToString())
print(unpacks[1].castToInt)
print(unpacks[2].castToDouble)
print(unpacks[3].castToBool)
print(unpacks[4].castToBool)
/* result
Optional("abcde")
123123
12323.24234
Optional(true)
Optional(false)
*/
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


