(local Object {})

(set Object.__index Object)

(fn Object.new [self])

(fn Object.extend [self]
  (let [cls {}]
    (each [k v (pairs self)]
      (when (= (k:find "__") 1)
        (tset cls k v)))
    (set cls.__index cls)
    (set cls.super self)
    (setmetatable cls self)
    cls))

(fn Object.implement [self ...]
  (each [_ cls (pairs {1 ...})]
    (each [k v (pairs cls)]
      (when (and (= (. self k) nil) (= (type v) :function))
        (tset self k v)))))

(fn Object.is [self T]
  (var mt (getmetatable self))
  (while mt
    (when (= mt T)
      (lua "return true"))
    (set mt (getmetatable mt)))
  false)

(fn Object.__tostring [self]
  :Object)

(fn Object.__call [self ...]
  (let [obj (setmetatable {} self)]
    (obj:new ...)
    obj))

Object

