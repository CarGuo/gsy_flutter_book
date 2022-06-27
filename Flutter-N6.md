# Flutter 小技巧之 Dart 里的 List 和 Iterable 你真的搞懂了吗？

今天我们介绍关于  `List` 和 `Iterable` 里有趣的知识点 ，你可能会觉得这有什么好介绍，不就是列表吗？但是其实在 Dart 里 `List` 和 `Iterable` 也是很有意思设定，比如有时候我们可以对 `List` 进行 `map` 操作，**如下代码所示，你觉得运行之后会打印出什么内容**？

```dart
var list = ["1", "2", "3", "4", "5"];
var map = list.map((e) {
  var result = int.parse(e) + 10;
  print("######### $result");
  return result;
});
```

**答案是：什么都不会输出，因为通过  `List `  返回一个 `Iterable` 的操作（如 `map` \  `where`）的都是 Lazy 的**，也就是它们只会在每次“迭代”时才会被调用。

比如调用 `toList();` 或者  `toString();` 等方法，就会触发上面的  `map`  执行，从而打印出对应的内容，**那新问题来了，假如我们把下图四个方法都执行一遍，会输出几次 log  ？em····答案是 3 次。**

![image-20220615164227346](http://img.cdn.guoshuyu.cn/20220615_N6/image1.png)

其中除了 `isEmpty` 之外，其他的三个操作都会重新触发 `map` 方法的执行，那究竟是为什么呢？

**其实当我们对一个 `List` 进行 `map` 等操作时，返回的是一个  `Iterable`  的 Lazy 对象，而每当我们需要访问里面 value 时，  `Iterable`   都会重新执行一遍操作，因为它不会对上次操作的结果进行缓存记录**。

 是不是有点懵？这里借用 [fast_immutable_collections ](https://pub.dev/packages/fast_immutable_collections) 作者的一个例子来介绍可能更会清晰，如下代码所示：

- 我们对同样的数组都调用了 `where` 去获取一个  `Iterable`  
- 区别在于在 `evenFilterEager` 里多调用了 `.toList()`  操作
- 每次 `where` 执行的时候都对各自的 Counter 进行 +1
- 最后分别调用三次 `length`，输出  Counter  结果

```dart
var lazyCounter = 0;
var eagerCounter = 0;

var lazyOddFilter = [1, 2, 3, 4, 5, 6, 7].where((i) {
  lazyCounter++;
  return i % 2 == 0;
});

var evenFilterEager = [1, 2, 3, 4, 5, 6, 7].where((i) {
  eagerCounter++;
  return i % 2 == 0;
}).toList();

print("\n\n---------- Init ----------\n\n");

lazyOddFilter.length;
lazyOddFilter.length;
lazyOddFilter.length;

evenFilterEager.length;
evenFilterEager.length;
evenFilterEager.length;

print("\n\n---------- Lazy vs Eager ----------\n\n");

print("Lazy: $lazyCounter");
print("Eager: $eagerCounter");

print("\n\n---------- END ----------\n\n");
```

如下图所示，这个例子最终会输出  Lazy: 21  Eager: 7 这样的结果：

- 因为  `lazyCounter` 每次调用 length 都是直接操作 `Iterable`  这个对象 ，所以每次都会重新执行一次 `where` ，所以 3 * 7 = 21
- 而 `eagerCounter` 对应的是 `toList();` ，在调用   `toList();`  时就执行了 7 次  `where`  ，之后不管调用几次  length 都和 `where`  的  `Iterable`   无关

![image-20220615165605170](http://img.cdn.guoshuyu.cn/20220615_N6/image2.png)

到这里你应该理解了  `Iterable`  的 Lazy 性质的特殊之处了吧？

那接下来看一个升级的例子，如下代码所示，我们依然是分了 eager 和 lazy 两组做对比，只是这次我们在  `where` 里添加了判断条件，并且做了嵌套调用，那么你觉得输出结果会是什么？

```dart
List<int> removeOdd_eager(Iterable<int> source) {
  return source.where((i) {
    print("removeOdd_eager");
    return i % 2 == 0;
  }).toList();
}

List<int> removeLessThan10_eager(Iterable<int> source) {
  return source.where((i) {
    print("removeLessThan10_eager");
    return i >= 10;
  }).toList();
}

Iterable<int> removeOdd_lazy(Iterable<int> source) {
  return source.where((i) {
    print("removeOdd_lazy");
    return i % 2 == 0;
  });
}

Iterable<int> removeLessThan10_lazy(Iterable<int> source) {
  return source.where((i) {
    print("removeLessThan10_lazy");
    return i >= 10;
  });
}

var list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

print("\n\n---------- Init ----------\n\n");

Iterable<int> eager = removeLessThan10_eager(removeOdd_eager(list));

Iterable<int> lazy = removeLessThan10_lazy(removeOdd_lazy(list));

print("\n\n---------- Lazy ----------\n\n");

print(lazy);

print("\n\n---------- Eager ----------\n\n");

print(eager);
```

如下所示，可以看到 ：

- 虽然我们先 `print(lazy);` 之后才输出 `print(eager);` ，但是先输出的还是 `removeOdd_eager` ，因为 Eager 相关的调用里有 `.toList();`  ，它在  `removeOdd_eager(list)` 时就执行了，所以会先完整输出  `removeOdd_eager` 之后再完整输出 `removeLessThan10_eager` ，最后在我们 `print(eager);` 的时候输出值 
- lazy 因为是 `Iterable ` ，所以只有被操作时才会输出，并且输出规律是：**输出两次 `removeOdd_lazy` 之后输出一次  `removeLessThan10_lazy`** ，因为从数据源 1-15 上，每两次就符合 `i % 2 == 0;` 的条件，所以会执行  `removeLessThan10_lazy`  ，从而变成这样的规律执行

```dart
I/flutter (23298): ---------- Init ----------
I/flutter (23298): 
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeOdd_eager
I/flutter (23298): removeLessThan10_eager
I/flutter (23298): removeLessThan10_eager
I/flutter (23298): removeLessThan10_eager
I/flutter (23298): removeLessThan10_eager
I/flutter (23298): removeLessThan10_eager
I/flutter (23298): removeLessThan10_eager
I/flutter (23298): removeLessThan10_eager
I/flutter (23298): ---------- Lazy ----------
I/flutter (23298): 
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeLessThan10_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeLessThan10_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeLessThan10_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeLessThan10_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeLessThan10_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeLessThan10_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): removeLessThan10_lazy
I/flutter (23298): removeOdd_lazy
I/flutter (23298): (10, 12, 14)
I/flutter (23298): ---------- Eager ----------
I/flutter (23298): 
I/flutter (23298): [10, 12, 14]
```

是不是很觉得，这种时候 `Iterable ` 把事情变得很复杂？ 确实在这种复杂嵌套的时候， `Iterable `  会把逻辑变得很难维护，而官方也表示：

> 由于 `Iterable ` 可能被多次迭代，因此不建议在迭代器中使用 side-effects 。 

那了解  `Iterable `  有什么用？或者说  `Iterable ` 可以用在什么场景？其实还是不少， 例如：

- 分页，可以确保只有适合用户屏幕渲染时，才执行对应逻辑去加载数据
- 数据库查询，可以实现使用数据时执行的懒加载效果，并且每次都重新迭代数据请求

举个例子，如下代码所示，感受下 `naturalsFunc` 这里 `Iterable` 配合 `Stream`  为什么可以正常：

```dart
Iterable<int> naturalsFunc() sync* {
  int k = 0;
  // Infinite loop!
  while (true) yield k++;
}

var naturalsIter = naturalsFunc();

print("\n\n---------- Init ----------\n\n");
print("The infinite list/iterable was created, but not evaluated.");
print("\n\n--------------------\n\n");
print("\n\n---------- takeWhile ----------\n\n");
print("It's possible to work with it,"
    "but it's necessary to add a method to "
    "stop the processing at some point");
var naturalsUpTo10 = naturalsIter.takeWhile((value) => value <= 10);
print("Naturals up to 10: $naturalsUpTo10");
print("\n\n---------- END ----------\n\n");
```

![image-20220615173602586](http://img.cdn.guoshuyu.cn/20220615_N6/image3.png)

那到这里你可能会问：**`List` 不也是 `Iterable `  么，它和 `map `、`where` 、`expand` 等操作返回的  `Iterable `   又有什么区别** ？

如果我们看  `List`  本身，你会看到它是一个 abstract 对象，它作为 `Iterable` 的子类，其实一般情况下实现对象会是 dart vm 里的 `_GrowableList`，而  `_GrowableList` 的结构关系如下图所示：

![image-20220615155944141](http://img.cdn.guoshuyu.cn/20220615_N6/image4.png)

而 `List` 和其他  `Iterable`  的不同在于在于：

- `List` 是具有长度的可索引集合，因为其内部  `ListIterator` 是通过  `_iterable.length;` 和  `_iterable.elementAt` 来进行实现
- 普通  `Iterable`   ，如 `map` 操作后的 `MappedIterable` 是按顺序访问的集合，通过  `MappedIterator` 来顺序访问 `iterable` 的元素，也不关心 length

![image-20220615182431493](http://img.cdn.guoshuyu.cn/20220615_N6/image5.png)

最后做个总结：本篇的知识点很单一，内容也很简单，就是带大家快速感受下 **`List` 和一般 `Iterable ` 的区别，并且通过例子理解 `Iterable `  懒加载的特性和应用场景**，这样有利于在开发过程中  `Iterable `  进行选型和问题定位。

如果你还有什么疑惑，欢迎留言评论。





