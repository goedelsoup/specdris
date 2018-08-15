[![Build Status](https://travis-ci.org/pheymann/specdris.svg?branch=master)](https://travis-ci.org/pheymann/specdris)

# specdris
With this framework you can write spec-like **Unit Tests** in Idris:

```Idris
import Specdris.Spec

main : IO ()
main = spec $ do
  describe "This is my math test" $ do
    it "adds two natural numbers" $ do
      (1 + 1) `shouldBe` 2
    it "multiplies two natural numbers" $ do
      (2 * 2) `shouldBe` 3
    it "do fancy stuff with complex numbers" $ do
      pendingWith "do this later"
```
You can also nest `describe`. When executed this spec it will produce the following output:

```
This is my math test
  + adds two natural numbers
  + multiplies two natural numbers
    [x] not equal --red
        actual:   4
        expected: 3
  + do fancy stuff with complex numbers
    [] pending: do this later -- yellow
    
Failed: Total = 3, Failed = 1, Pending = 1 -- red
```

You can also test your `IO` code:

```Idris
import Specdris.SpecIO

main : IO ()
main = specIO $ do
  describe "This is my side effect test" $ do
    it "say my name" $ do
      name <- loadName
      
      pure $ name `shouldBe` "Foo"
```

You can find more information about `SpecIO` [here](#specio).

Both `spec` and `specIO` have backend-agnostic versions, respectively `spec'`
and `specIO'`, that use `IO'` rather than `IO`.

## Install
This testing framework is written with `Idris 1.0`.

Clone the repo from github with `git clone https://github.com/pheymann/specdris.git` and run:

```
cd specdris
./project --install

# under windows
.\Project.ps1 --install
```

### elba
If you use [elba](https://github.com/elba/elba) to manage your Idris packages,
you can also add specdris as a dev-dependency to be run during tests. Just add
the following to the `[dev_dependencies]` section of your package's
`elba.toml` manifest:

```toml
[dev_dependencies]
# snip
"pheymann/specdris" = { git = "https://github.com/pheymann/specdris" }
```

Then you'll be able to use specdris from all test targets.

## Documentation
### Expectations
Currently this framework provides you with:

|Expectation|Alias|Description|
|----------|-----|-----------|
|`a shouldBe b`|`===`|is `a` equal to `b`|
|`a shouldNotBe b`|`/==`|is `a` unequal to `b`|
|`a shouldBeTrue`| |is `a` `True`|
|`a shouldBeFalse` | | is `a` `False`|
|`a shouldSatisfy pred`| | satisfies `a` a given predicate|
|`a shouldBeJust exp` | | if `a` is `Just a'` apply `exp` to `a'`; here `exp` is again a sequence of expectations |

### Failed Test Cases
If an expectations in a test case failes the following expectations aren't executed and the
whole case is marked as failure:

```Idris
  it "failing test" $ do
    1 `shouldBe` 1 -- success
    2 `shouldBe` 1 -- failes
    2 `shouldBe` 2 -- will not be executed
```

### SpecIO
Besides the usual test cases you can also add effects as:

#### BeforeAll
Executes an `IO ()` before running any test case:

```Idris
specIO {beforeAll = putStrLn "hello"} $ do ...
```

#### AfterAll
Executes an `IO ()` after all test cases are executed:

```Idris
specIO {afterAll = putStrLn "bye"} $ do ...
```

#### Around
Takes a function `IO SpecResult -> IO SpecResult` which can be used to execute `IO` code
before and after every test case:

```Idris
around : IO SpecResult -> IO SpecResult
around resultIO = do putStrLn "hello"
                     result <- resultIO
                     putStrLn "bye"
                     
                     pure result

specIO {around = around} $ do
```

### Shuffle/Randomise Test Case Execution
You can randomise your test case execution by applying `shuffle` to your spec:

```Idris
mySpec : SpecTree
mySpec = 
  describe "my test"
    it "a" $ 1 === 1
    it "b" $ 2 === 2

-- default seed
spec $ shuffle mySpec

-- static seed
spec $ shuffle mySpec 1000

-- current time
do seed <- System.time
   spec $ shuffle mySpec seed
```

`shuffle` only changes execution order for tests (`it`) under a `decribe` and thus preserves the logical test structure.

### Creating your own Expectations
If you need other expections than these provided [here](https://github.com/pheymann/specdris/blob/master/src/Specdris/Expectations.idr) 
you can implement them as follows:

```Idris
shouldParse: (Show a, Eq, a) => Parser -> (actual : String) -> (expected : a) -> SpecResult
shouldParse: parser actual expected 
  = case parser actual of
      (Right result) => result === expected
      (Left err)     => UnaryFailure actual $ "couldn't parse: " ++ err
```

### Working with SpecState
It is possible to get the [SpecState](https://github.com/pheymann/specdris/blob/master/src/Specdris/Data/SpecState.idr#L8-L16)
record of a spec after its execution by using `specWithState` from *Spec* or *SpecIO*.

#### Storing Console Output in SpecState
If you want to process the output after spec execution you can store it in [SpecState](https://github.com/pheymann/specdris/blob/master/src/Specdris/Data/SpecState.idr#L8-L16)
by setting `spec {storeOutput = True}` or `specIO {storeOutput = True}`. This also stops *specdris* from printing
it to the console.
