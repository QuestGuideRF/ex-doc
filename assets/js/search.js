import $ from 'jquery'
import lunr from 'lunr'
import resultsTemplate from './templates/search-results.handlebars'
const $search = $('#поиск')
const $input = $('.sidebar-search ввод')
function fillResults (results) {
  var contents = searchNodes
  var matches = []
  results.forEach(function (element) {
    var item = contents.find(i => i.ref === element.ref)
    if (item) {
      var metadata = element.matchData.metadata
      item.metadata = metadata
      item.excerpts = getExcerpts(item, metadata)
      matches.push(item)
    }
  })
  return matches
}
function getExcerpts (item, metadata) {
  var terms = Object.keys(metadata)
  var excerpts = []
  var nchars = 80
  terms.forEach(function (term) {
    if ('doc' in metadata[term]) {
      metadata[term].doc.position.forEach(function (matchPos) {
        var startPos = matchPos[0] - nchars > 0 ? matchPos[0] - nchars : 0
        var endPos = matchPos[0] + matchPos[1] + nchars > item.doc.length
          ? item.doc.length : matchPos[0] + matchPos[1] + nchars
        var excerpt =
          (startPos > 0 ? '...' : '') +
          item.doc.slice(startPos, matchPos[0]) +
          '<эм>' +
          item.doc.slice(matchPos[0], matchPos[0] + matchPos[1]) +
          '</ем> ' +
          item.doc.slice(matchPos[0] + matchPos[1], endPos) +
          (endPos < item.doc.length ? '...' : '')
        excerpts.push(excerpt)
      })
    }
  })
  if (excerpts.length === 0) {
    excerpts.push(item.doc.slice(0, nchars * 2))
  }
  return excerpts.slice(0, 1)
}
export function search (value) {
  if (value.replace(/\s/, '') !== '') {
    $input.val(value)
    var idx = getIndex()
    var results, errorMessage
    try {
      results = fillResults(idx.search(value.replace(':', '')))
    } catch (error) {
      errorMessage = error.message
    }
    var resultsHtml = resultsTemplate({
      value: value,
      results: results,
      errorMessage: errorMessage
    })
    $search.html(resultsHtml)
  } else {
    $search.html('<h1>Search</h1>')
  }
}
function getIndex () {
  var projectMeta = getProjectMeta()
  var stored = sessionStorage.getItem(projectMeta)
  try {
    if (stored == null) throw 'создать и сохранить'
    return lunr.Index.load(JSON.parse(stored))
  } catch {
    var idx = createIndex()
    var stringified = JSON.stringify(idx)
    try {
      sessionStorage.setItem(projectMeta, stringified)
    } catch {
    }
    return idx
  }
}
function getProjectMeta () {
  return document.head.querySelector('мета[имя=проект][содержание]').content
}
function titleExtractor (document) {
  var title = document['title']
  if (document['type'] !== 'extras') {
    title = title + ' ' + title.replace(/\.|\//g, ' ')
  }
  return title
}
function createIndex () {
  return lunr(function () {
    this.ref('ref')
    this.field('title', {extractor: titleExtractor})
    this.field('doc')
    this.metadataWhitelist = ['position']
    this.pipeline.remove(lunr.stopWordFilter)
    searchNodes.forEach(function (doc) {
      this.add(doc)
    }, this)
  })
}