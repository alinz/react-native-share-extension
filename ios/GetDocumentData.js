// prettier-ignore
/* eslint-disable */
var GetDocumentData = function() {};

GetDocumentData.prototype = {
  run: function(arguments) {
    var documentUrl = document.URL;
    var documentOuterHTML = document.documentElement.outerHTML;
    var documentTitle = document.title;

    var data = {
      url: documentUrl,
      html: documentOuterHTML,
      title: documentTitle
    }

    var documentData = JSON.stringify(data);

    arguments.completionFunction({ "documentData": documentData });
  }
};

var ExtensionPreprocessingJS = new GetDocumentData;
