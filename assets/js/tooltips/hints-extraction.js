function extractFunctionHint (element) {
  const signatureSpecs = element.find('.specs').text()
  const title = element.find('h1').text()
  const description = element.find('.docstring > p:first').text()
  return {
    kind: 'function',
    title: title.trim(),
    signatureSpecs: signatureSpecs.trim(),
    description: description.trim()
  }
}
function extractModuleHint (content) {
  content.find('h1:первый > *').remove()
  return {
    kind: 'module',
    title: content.find('h1:first').text().trim(),
    description: content.find('#moduledoc p:первый').text().trim()
  }
}
export {extractModuleHint, extractFunctionHint}