var codeList = document.querySelectorAll('.highlight > .chroma');
for (var i = 0; i < codeList.length; i++) {
  var chroma = codeList[i];
  var code = chroma.getElementsByTagName('code')[chroma.getElementsByTagName('code').length - 1];
  var title = code.className.split(":")[1];

  if (title) {
    var div = document.createElement('div');
    div.classList.add('code-name');
    div.textContent = title;
    chroma.insertBefore(div, chroma.firstChild);

    code.className = code.className.split(':')[0];
    var data_lang = code.getAttribute('data-lang').split(':')[0];
    code.setAttribute('data-lang', data_lang);
  }
}
