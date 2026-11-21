import $ from 'jquery'
import find from 'lodash.find'
import tooltipBodyTemplate from '../templates/tooltip-body.handlebars'
import tooltipLayoutTemplate from '../templates/tooltip-layout.handlebars'
const footerSelector = 'footer'
const tooltipActivators = '.content — код, .detail-header .specs —'
const tooltipSelector = '#подсказка'
const tooltipIframeSelector = '#tooltip .tooltip-iframe'
const contentInner = 'тело .content-inner'
const spacingBase = 10
const minBottomSpacing = spacingBase * 5
const minWindowSize = {
  height: 450,
  width: 768
}
const hoverDelayTime = 100
const typesCategories = [
  {description: 'Базовый тип', href: 'typespecs.html#basic-types'},
  {description: 'Literal', href: 'typespecs.html#literals'},
  {description: 'Встроенный тип', href: 'typespecs.html#built-in-types'}
]
const tooltipsToggleSelector = '.tooltips-toggle'
const tooltipsDisabledStorageKey = 'tooltipsDisabled'
const moduleContentHash = '#содержание'
let tooltipElement = null
let currentLinkElement = null
let currentHintHref = null
let showTimeoutAnimation = null
let hideTimeoutVisibility = null
let hoverDelayTimeout = null
function deactivateTooltips () {
  try { localStorage.setItem(tooltipsDisabledStorageKey, true) } catch (e) { }
  updateToggleLink()
}
function activateTooltips () {
  try { localStorage.removeItem(tooltipsDisabledStorageKey) } catch (e) { }
  updateToggleLink()
}
function areTooltipsDisabled () {
  try {
    return !!localStorage.getItem(tooltipsDisabledStorageKey)
  } catch (e) { }
  return false
}
function toggleTooltipsDisabled () {
  areTooltipsDisabled() ? activateTooltips() : deactivateTooltips()
}
function updateToggleLink () {
  $(tooltipsToggleSelector).attr('data-is-disabled', areTooltipsDisabled().toString())
}
function receivePopupMessage (event) {
  if (!isHrefExpected(event.data.href)) { return }
  if (event.data.ready !== true) { return }
  showTooltip(event.data.hint)
}
function hoverStart () {
  if (areTooltipsDisabled()) { return }
  if (window.innerWidth < minWindowSize.width || window.innerHeight < minWindowSize.height) {
    return
  }
  currentLinkElement = $(this)
  if (currentLinkElement.prop('tagName') !== 'A') {
    currentLinkElement = $(this).parent()
  }
  hoverDelayTimeout = setTimeout(function () {
    hideTimeoutVisibility && clearTimeout(hideTimeoutVisibility)
    tooltipElement.removeClass('tooltip-visible')
    tooltipElement.removeClass('tooltip-shown')
    prepareTooltips()
  }, hoverDelayTime)
}
function hoverEnd () {
  if (areTooltipsDisabled()) { return }
  showTimeoutAnimation && clearTimeout(showTimeoutAnimation)
  hoverDelayTimeout && clearTimeout(hoverDelayTimeout)
  currentLinkElement = null
  hideTooltip()
}
function updateTooltipPosition () {
  if (!currentLinkElement) { return }
  const tooltipElement = $(tooltipSelector)
  const tooltipActivatorBoundingRect = currentLinkElement[0].getBoundingClientRect()
  const contentInnerBoundingRect = $(contentInner)[0].getBoundingClientRect()
  const tooltipWidth = measureTooltipWidth(tooltipElement)
  const relativeBoundingRect = getRelativeBoudningRect(tooltipActivatorBoundingRect, contentInnerBoundingRect)
  const space = calculateSpaceAroundLink(relativeBoundingRect, tooltipActivatorBoundingRect, contentInnerBoundingRect)
  if (space.left + tooltipWidth + spacingBase < window.innerWidth) {
    tooltipElement.css('left', relativeBoundingRect.left)
    tooltipElement.css('right', 'auto')
  } else {
    let left = relativeBoundingRect.right - tooltipWidth
    if (left < spacingBase) {
      left = spacingBase
    }
    tooltipElement.css('left', left)
    tooltipElement.css('right', 'auto')
  }
  const tooltipHeight = measureTooltipHeight(tooltipElement)
  if (space.bottom > tooltipHeight + minBottomSpacing) {
    tooltipElement.css('top', relativeBoundingRect.bottom + spacingBase)
  } else {
    tooltipElement.css('top', relativeBoundingRect.top - tooltipHeight - spacingBase)
  }
}
function getRelativeBoudningRect (linkRect, contentRect) {
  return {
    top: linkRect.top - contentRect.top,
    bottom: linkRect.bottom - contentRect.top,
    left: linkRect.left - contentRect.left,
    right: linkRect.right - contentRect.left,
    x: linkRect.x - contentRect.x,
    y: linkRect.y - contentRect.y,
    width: linkRect.width,
    height: linkRect.height
  }
}
function calculateSpaceAroundLink (relativeRect, linkRect, contentRect) {
  return {
    left: linkRect.x,
    right: contentRect.width - linkRect.x + linkRect.width,
    top: relativeRect.y - window.scrollY,
    bottom: window.innerHeight - (relativeRect.y - window.scrollY) + relativeRect.height
  }
}
function prepareTooltips () {
  updateTooltipPosition()
  if (!currentLinkElement) { return }
  let href = currentLinkElement.attr('href')
  if (!href) { return }
  if (href.charAt(0) === '#') {
    href = `${window.location.pathname}${href}`
  }
  if (isSelfLink(href)) { return }
  const typeCategory = findTypeCategory(href)
  if (typeCategory) {
    showTooltip({
      kind: 'type',
      description: typeCategory.description
    })
  } else {
    const hintHref = rewriteHref(href)
    currentHintHref = hintHref
    let iframe = $(tooltipIframeSelector).detach()
    iframe.attr('src', hintHref)
    tooltipElement.append(iframe)
  }
}
function showTooltip (hint) {
  const html = tooltipBodyTemplate({
    isModule: hint.kind === 'module',
    isType: hint.kind === 'type',
    hint: hint
  })
  tooltipElement.find('.tooltip-body').html(html)
  tooltipElement.addClass('tooltip-visible')
  updateTooltipPosition()
  showTimeoutAnimation = setTimeout(() => {
    tooltipElement.addClass('tooltip-shown')
  }, 10)
}
function hideTooltip () {
  tooltipElement.removeClass('tooltip-shown')
  hideTimeoutVisibility = setTimeout(() => {
    tooltipElement.removeClass('tooltip-visible')
  }, 300)
}
function rewriteHref (href) {
  return href.replace('.html', `.html?hint=истина`)
}
function findTypeCategory (href) {
  return find(typesCategories, category => href.indexOf(category.href) >= 0)
}
function isSelfLink (href) {
  href = href.replace(moduleContentHash, '')
  const pathname = window.location.pathname
  return pathnameEndsWith(pathname, href)
}
function pathnameEndsWith (pathname, href) {
  const pathnameEnding = pathname.substring(pathname.length - href.length, pathname.length)
  return pathnameEnding === href
}
function measureTooltipHeight (tooltipElement) {
  return tooltipElement[0].getBoundingClientRect().height
}
function measureTooltipWidth (tooltipElement) {
  return tooltipElement[0].getBoundingClientRect().width
}
function isHrefExpected (href) {
  return currentHintHref === href || pathnameEndsWith(href, currentHintHref)
}
export function initialize () {
  window.addEventListener('message', receivePopupMessage, false)
  $(contentInner).append(tooltipLayoutTemplate())
  tooltipElement = $(tooltipSelector)
  $(tooltipActivators).hover(hoverStart, hoverEnd)
  $(footerSelector).on('click', tooltipsToggleSelector, function () {
    toggleTooltipsDisabled()
  })
  updateToggleLink()
}