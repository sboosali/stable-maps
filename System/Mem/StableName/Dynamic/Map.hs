{-# LANGUAGE CPP #-}
#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ >= 702
{-# LANGUAGE Unsafe #-}
#endif
module System.Mem.StableName.Dynamic.Map
    ( Map
    , empty
    , null
    , singleton
    , member
    , notMember
    , insert
    , insertWith
    , insertWith'
    , lookup
    , find
    , findWithDefault
    ) where

import qualified Prelude
import Prelude hiding (lookup, null)
import System.Mem.StableName.Dynamic
import qualified Data.IntMap as IntMap
import Data.IntMap (IntMap)

newtype Map a = Map { getMap :: IntMap [(DynamicStableName, a)] } 

empty :: Map a
empty = Map IntMap.empty

null :: Map a -> Bool
null (Map m) = IntMap.null m

singleton :: DynamicStableName -> a -> Map a
singleton k v = Map $ IntMap.singleton (hashDynamicStableName k) [(k,v)]

member :: DynamicStableName -> Map a -> Bool
member k m = case lookup k m of
    Nothing -> False
    Just _ -> True

notMember :: DynamicStableName -> Map a -> Bool
notMember k m = not $ member k m 

insert :: DynamicStableName -> a -> Map a -> Map a
insert k v = Map . IntMap.insertWith (++) (hashDynamicStableName k) [(k,v)] . getMap
    
-- | /O(log n)/. Insert with a function for combining the new value and old value.
-- @'insertWith' f key value mp@
-- will insert the pair (key, value) into @mp@ if the key does not exist
-- in the map. If the key does exist, the function will insert the pair
-- @(key, f new_value old_value)@
insertWith :: (a -> a -> a) -> DynamicStableName -> a -> Map a -> Map a
insertWith f k v = Map . IntMap.insertWith go (hashDynamicStableName k) [(k,v)] . getMap 
    where 
        go _ ((k',v'):kvs) 
            | k == k' = (k', f v v') : kvs
            | otherwise = (k',v') : go undefined kvs
        go _ [] = []

-- | Same as 'insertWith', but with the combining function applied strictly.
insertWith' :: (a -> a -> a) -> DynamicStableName -> a -> Map a -> Map a
insertWith' f k v = Map . IntMap.insertWith go (hashDynamicStableName k) [(k,v)] . getMap 
    where 
        go _ ((k',v'):kvs) 
            | k == k' = let v'' = f v v' in v'' `seq` (k', v'') : kvs
            | otherwise = (k', v') : go undefined kvs
        go _ [] = []

-- | /O(log n)/. Lookup the value at a key in the map.
-- 
-- The function will return the corresponding value as a @('Just' value)@
-- or 'Nothing' if the key isn't in the map.
lookup :: DynamicStableName -> Map v -> Maybe v
lookup k (Map m) = do
    pairs <- IntMap.lookup (hashDynamicStableName k) m
    Prelude.lookup k pairs

find :: DynamicStableName -> Map v -> v
find k m = case lookup k m of
    Nothing -> error "Map.find: element not in the map"
    Just x -> x 

-- | /O(log n)/. The expression @('findWithDefault' def k map)@ returns
-- the value at key @k@ or returns the default value @def@
-- when the key is not in the map.
findWithDefault :: v -> DynamicStableName -> Map v -> v
findWithDefault dflt k m = maybe dflt id $ lookup k m 
