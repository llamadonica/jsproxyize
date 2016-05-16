// Copyright (c) 2016, Adam Stark. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for creating JsProxy object on the fly.
library jsproxyize;

/// Annotation type that mimics the `PolymerReflectable` annotation in
/// polymer.
class PolymerReflectable {
  const PolymerReflectable();
}

const reflectable = const PolymerReflectable();

/// Use this annotation to indicate that a type will be "upgraded" to a JsProxy
/// when run through the jsproxyize transformer.
class JsProxyize {
  const JsProxyize();
}

const JsProxyize jsProxyize = const JsProxyize();
