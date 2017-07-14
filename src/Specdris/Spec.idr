||| Central module use to import the Specdris test framework
module Specdris.Spec

import System

import public Specdris.Data.SpecState
import public Specdris.Data.SpecResult
import public Specdris.Data.SpecInfo

import public Specdris.Core
import public Specdris.Expectations

import Specdris.Data.ConsoleColor

%access export
%default total

||| Adds a context/description to the spec test. It can have
||| nested descriptions or spec cases.
describe: (description : String) -> SpecTree -> SpecTree
describe descr tree = Node (Leaf $ Left $ Describe descr)
                           (tree)

||| Adds a spec case to the spec test. Spec cases consist only
||| of expectations. Nested spec cases or descriptions are not
||| allowed.
it : (description : String) -> SpecResult -> SpecTree
it descr spec = Node (Leaf $ Left $ It $ descr)
                     (Leaf $ Right $ pure spec)

||| Executes a spec test and prints the result to the command line.
specWithState : {default False storeOutput : Bool} -> SpecTree -> IO SpecState
specWithState {storeOutput} tree
  = do state <- evaluate (\spec => spec) storeOutput tree
       
       putStrLn $ "\n" ++ stateToStr state
       pure state
  where
    stateToStr : SpecState -> String
    stateToStr state
      = colorise (if failed state == 0 then Green else Red) $
          indent 1
            ++ (if failed state == 0 then "Passed" else "Failed") ++ ": "
            ++ show state

||| Executes a spec test and prints the result to the command line.
spec : SpecTree -> IO ()
spec tree
  = do state <- specWithState tree
       if (failed state) > 0 then
         exitFailure
       else
         pure ()
