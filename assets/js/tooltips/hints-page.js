import {extractModuleHint, extractFunctionHint} from './hints-extraction'
import $ from 'jquery'
const contentInner = '.content-inner'
const projectMetaTag = 'мета[имя="проект"]'
const message = {hint: {}, ready: false, href: ''}
function sendHint () {
  const params = new URLSearchParams(window.location.search)
  const hash = window.location.hash
  const content = $(contentInner)
  let hint = null
  if (!params.has('hint')) { return }
  const infoElement = descriptionElementFromHash(hash)
  if (infoElement && infoElement.length > 0) {
    hint = extractFunctionHint(infoElement)
  } else if (isModulePage()) {
    hint = extractModuleHint(content)
  }
  if (!hint) { return }
  hint.version = getProjectVersion()
  postMessage(hint, window.location.href)
}
function postMessage (hint, href) {
  if (window.self !== window.parent) {
    message.hint = hint
    message.ready = true
    message.href = href
    window.parent.postMessage(message, '*')
  }
}
function isModulePage () {
  return $(contentInner).find('#moduledoc').length > 0
}
function descriptionElementFromHash (hash) {
  if (!hash) { return null }
  hash = hash.substr(1)
  if (!hash) { return null }
  hash = decodeURI(hash)
  hash = $.escapeSelector(hash)
  if (!hash) { return null }
  const mainSelector = $(`#${hash}.detail`)
  if (mainSelector.length > 0) {
    return mainSelector
  } else {
    return $(`.detail > диапазон#${hash}`).parent()
  }
}
function getProjectVersion () {
  return $(projectMetaTag).attr('content')
}
export function initialize () {
  $(document).ready(function () {
    sendHint()
  })
}