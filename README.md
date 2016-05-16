# jsproxyize

A library for Dart Polymer developers. By decorating a class with the @JsProxyize()
annotation, you can mark a class that will be transformed to a JsProxy instance
with the built-in transformer. That way you can reuse your models between client
and server code.

## Usage

A simple usage example:

    library contacts.contact;

    import "package:redstone_mapper/mapper.dart";
    import "package:redstone_mapper_mongo/metadata.dart";

    import "package:io_2016_contacts_demo/transformer/metadata.dart";

    @jsProxyize class Contact {

      @Id() @reflectable String id;
      @Field() @reflectable String name;
      @Field() @reflectable String notes;
      @Field() @reflectable bool important;

      Contact([this.name, this.notes, this.important, this.id]);
    }

Then in your transformers, add:

    ...

    transformers:
    - io_2016_contacts_demo
    ...

This will, at transformation time, convert the object into an object that extends
JsProxy.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/llamadonica/jsproxyize/issues
