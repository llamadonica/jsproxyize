/// The transformer that consumes the metadata.
library jsproxyize_transformer;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:code_transformers/resolver.dart';
import 'package:barback/barback.dart';
import 'package:source_maps/refactor.dart' show TextEditTransaction;
import 'package:path/path.dart' as path;

class JsProxyizeTransformer extends Transformer with ResolverTransformer {

  ClassElement classAnnotationClass;


  JsProxyizeTransformer.asPlugin(BarbackSettings settings) {
    var sdkDir = settings.configuration["dart_sdk"];
    if (sdkDir == null) {
      // Assume the Pub executable is always coming from the SDK.
      sdkDir = path.dirname(path.dirname(Platform.executable));
    }
    resolvers = new Resolvers(sdkDir);
  }

  @override
  Future<bool> isPrimary(assetOrId) async {
    // assetOrId is to handle the transition from Asset to AssetID between
    // pub 1.3 and 1.4. Once support for 1.3 is dropped this should only
    // support AssetId.
    AssetId id = assetOrId is AssetId ? assetOrId : assetOrId.id;
    return id.extension == '.dart';
  }

  @override
  Future<bool> shouldApplyResolver(Asset asset) async {
    if (asset.id.extension != '.dart') return false;
    return true;
  }

  @override
  Future applyResolver(Transform transform, Resolver resolver) async {
    var library = resolver.getLibraryByName('jsproxyize');

    if (library == null) {
      transform.addOutput(transform.primaryInput);
      return;
    }
    var thisLibrary = resolver.getLibrary(transform.primaryInput.id);
    List<Element> metadataToRemove = new List<Element>();
    List<ClassElement> types = thisLibrary
        .units
        .expand((unit) => unit.types)
        .where((ClassElement type) => type.metadata.any((metadatum) {
      if (metadatum.element.library != library) return false;
      var metadatumElement = metadatum.element;
      String annotation;
      if (metadatumElement is ConstructorElement) {
        annotation = metadatumElement.type.returnType.displayName;
      } else {
        annotation = metadatumElement.displayName;
      }
      if (['jsProxyize', 'JsProxyize'].contains(annotation)) {
        metadataToRemove.add(metadatumElement);
        return true;
      }
      return false;
    }))
        .toList(growable: false);
    if (types.length == 0) {
      transform.addOutput(transform.primaryInput);
      return;
    }
    for (var clazz in types) {
      print(clazz);
    }
    print(library);
    var lib = resolver.getLibrary(transform.primaryInput.id);
    var transaction = resolver.createTextEditTransaction(lib);
    var unit = lib.definingCompilationUnit.computeNode();
    for (var directive in unit.directives) {
      if (directive is ImportDirective && directive.uri.stringValue == 'package:jsproxyize/jsproxyize.dart') {
        var uri = directive.uri;
        transaction.edit(uri.beginToken.offset, uri.end, "'package:polymer/polymer.dart'");
      }
    }
    var jsProxyizeTojsProxy = new _MapperJsProxyizeToJsProxy(transaction, types, metadataToRemove);
    unit.accept(jsProxyizeTojsProxy);
    var printer = transaction.commit();
    var url = transform.primaryInput.id.path.startsWith('lib/')
        ? 'package:${transform.primaryInput.id.package}/${transform.primaryInput.id.path.substring(4)}'
        : transform.primaryInput.id.path;
    printer.build(url);
    transform.addOutput(new Asset.fromString(transform.primaryInput.id, printer.text));
  }
}

class _MapperJsProxyizeToJsProxy extends GeneralizingAstVisitor {
  final TextEditTransaction transaction;
  final List<ClassElement> elementsToEdit;
  final List<Element> metadataToRemove;
  _MapperJsProxyizeToJsProxy(this.transaction, this.elementsToEdit, this.metadataToRemove);

  visitClassDeclaration(ClassDeclaration node) {
    if (!elementsToEdit.contains(node.element)) return;
    for (var metadatumToTest in node.metadata) {
      if (metadataToRemove.contains(metadatumToTest.element)) {
        transaction.edit(metadatumToTest.beginToken.offset, metadatumToTest.endToken.end, '');
      }
    }
    if (node.extendsClause == null && node.typeParameters == null) {
      transaction.edit(node.name.endToken.end, node.name.endToken.end, ' extends Object with JsProxy');
    } else if (node.extendsClause == null) {
      transaction.edit(node.typeParameters.endToken.end, node.typeParameters.endToken.end, ' extends Object with JsProxy');
    } else if (node.withClause == null) {
      transaction.edit(node.extendsClause.endToken.end, node.extendsClause.endToken.end, ' with JsProxy');
    } else {
      transaction.edit(node.withClause.endToken.end, node.withClause.endToken.end, ', JsProxy');
    }
  }

}