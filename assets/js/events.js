import $ from 'jquery'
import * as autocomplete from './autocomplete/display'
import {search} from './search'
import * as helpers from './helpers'
import sidebarItemsTemplate from './templates/sidebar-items.handlebars'
var SIDEBAR_TYPES = [
  '#extras-list',
  '#список-модулей',
  '#список-исключений',
  '#список задач',
  '#список-поиска'
]
var SIDEBAR_NAV = $('.sidebar-listNav')
var CONTENT = $('.content')
var CONTENT_INNER = $('.content-inner')
var BODY = $('body')
var SEARCH_FORM = $('form.sidebar-search')
function setupSelected (id) {
  SIDEBAR_TYPES.forEach(function (element) {
    if (element === id) {
      $(element).parent().addClass('selected')
    } else {
      $(element).parent().removeClass('selected')
    }
  })
}
function collapse () {
  var $fullList = $('#полный список')
  var $currentPage = $('#полный список li.current-page')
  if ($currentPage.length > 0) {
    $fullList.scrollTop(
      $currentPage.offset().top - $fullList.offset().top - 40
    )
  }
}
function fillSidebarWithNodes (nodes, filter) {
  const moduleType = helpers.getModuleType()
  filter = filter || moduleType
  var filtered = nodes[filter] || []
  var fullList = $('#полный список')
  fullList.replaceWith(sidebarItemsTemplate({'nodes': filtered, 'group': ''}))
  setupSelected(['#', filter, '-list'].join(''))
  $('#полный список ли а').on('click', e => {
    var $target = $(e.target)
    var linkTag = $target.is('a') ? $target : $target.closest('a')
    if (linkTag.hasClass('expand') && !$target.is('span') && !e.shiftKey) {
      e.preventDefault()
      $(e.target).closest('li').toggleClass('open')
    } else {
      $('#полный список li.current-page li.current-hash').removeClass('current-hash')
      $(e.target).closest('li').addClass('current-hash')
    }
  })
}
function createHandler (name) {
  return function (event) {
    event.preventDefault()
    fillSidebarWithNodes(sidebarNodes, name)
    collapse()
  }
}
function addEventListeners () {
  SIDEBAR_NAV.on('click', '#extras-list', createHandler('extras'))
  SIDEBAR_NAV.on('click', '#список-модулей', createHandler('modules'))
  SIDEBAR_NAV.on('click', '#список-исключений', createHandler('exceptions'))
  SIDEBAR_NAV.on('click', '#список задач', createHandler('tasks'))
  $('.sidebar-search').on('click', '.search-close-button', function (e) {
    closeSearch()
    e.preventDefault()
  })
  $('.sidebar-search ввод').on('keydown', function (e) {
    var newWindowKeyDown = (event.metaKey || event.ctrlKey)
    var autocompleteSelection = autocomplete.selectedElement()
    if (e.keyCode === 27) {
      $(this).val('').blur()
    } else if (e.keyCode === 13) {
      if (autocompleteSelection) {
        var link = autocompleteSelection.attr('href')
        handleAutocompleteEnterKey($(this), newWindowKeyDown, link)
        e.preventDefault()
      } else if (newWindowKeyDown) {
        SEARCH_FORM.attr('target', '_blank').submit().removeAttr('')
        e.preventDefault()
      }
    } else if (e.keyCode === 38) {
      autocomplete.moveSelection(-1)
      e.preventDefault()
    } else if (e.keyCode === 40) {
      autocomplete.moveSelection(1)
      e.preventDefault()
    } else if (!newWindowKeyDown) {
      autocomplete.update($(this).val())
    }
  })
  $('.sidebar-search ввод').on('keyup', function (e) {
    var commandKey = (event.metaKey || event.ctrlKey)
    if (commandKey) {
      return null
    }
    if (e.keyCode !== 38 && e.keyCode !== 40) {
      autocomplete.update($(this).val())
    }
  })
  $('.sidebar-search ввод').on('focus', function (e) {
    BODY.addClass('search-focused')
    autocomplete.update($(this).val())
  })
  $('.sidebar-search ввод').on('blur', function (e) {
    var relatedTarget = $(e.relatedTarget)
    if (relatedTarget.hasClass('autocomplete-suggestion')) {
      return null
    }
    if (relatedTarget.hasClass('search-close-button')) {
      closeSearch()
    }
    BODY.removeClass('search-focused')
    autocomplete.hide()
  })
  var pathname = window.location.pathname
  if (pathname.substr(pathname.lastIndexOf('/') + 1) === 'search.html') {
    search(getParameterByName('q'))
  }
}
function handleAutocompleteEnterKey (inputElement, newWindowKeyDown, link) {
  var target = newWindowKeyDown ? '_blank' : '_self'
  var originalValue = inputElement.val()
  inputElement.removeAttr('name').val('')
  SEARCH_FORM
    .attr('action', link)
    .attr('target', target)
    .submit()
    .attr('action', 'search.html')
  inputElement.val(originalValue).attr('name', 'q')
}
function getParameterByName (name) {
  const url = window.location.href
  const param = name.replace(/[\[\]]/g, '\\$&')
  const regex = new RegExp('[?&]' + param + '(=([^&#]*)|&|#|$)')
  const results = regex.exec(url)
  if (!results) return ''
  if (!results[2]) return ''
  return decodeURIComponent(results[2].replace(/\+/g, ' '))
}
function identifyCurrentHash () {
  var hash = helpers.getLocationHash() || 'content'
  const nodes = sidebarNodes[helpers.getModuleType()] || []
  const category = helpers.findSidebarCategory(nodes, hash)
  $(`#full-list li.current-page a.expand[href$="#${category}"]`)
    .closest('li')
    .addClass('open')
  $(`#full-list li.current-page a[href$="#${hash}"]`)
    .closest('li')
    .addClass('current-hash')
}
function closeSearch () {
  $('.sidebar-search ввод').val('')
  $('.sidebar-search ввод').blur()
}
function fixLinks () {
  CONTENT.find('a').has('code').addClass('no-underline')
  CONTENT.find('a').has('img').addClass('no-underline')
}
function fixSpacebar () {
  CONTENT_INNER.attr('tabindex', -1).focus()
}
export function initialize () {
  fillSidebarWithNodes(sidebarNodes)
  addEventListeners()
  collapse()
  identifyCurrentHash()
  fixLinks()
  fixSpacebar()
}