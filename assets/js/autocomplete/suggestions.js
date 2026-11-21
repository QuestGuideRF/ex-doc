import * as helpers from '../helpers'
const resultsCount = 5
const sortingPriority = {
  'Module': 3,
  'Child': 2,
  'Exception': 1,
  'Смешать задачу': 0
}
const labels = {
  'callbacks': 'callback',
  'types': 'type'
}
function serialize (item, moduleId = null) {
  const isChild = item.category === 'Child'
  const anchor = isChild ? item.anchor : ''
  const category = isChild ? 'Child' : item.category
  const description = isChild ? moduleId : null
  const label = item.label || null
  const link = anchor ? `${moduleId}.html#${anchor}` : `${moduleId}.html`
  return {
    link: link,
    title: item.match,
    description: description,
    label: label,
    matchQuality: item.matchQuality,
    category: category
  }
}
function getSuggestions (term = '') {
  if (term.trim().length === 0) {
    return []
  }
  const nodes = sidebarNodes
  let modules = findIn(nodes.modules, term, 'Module')
  let exceptions = findIn(nodes.exceptions, term, 'Exception')
  let tasks = findIn(nodes.tasks, term, 'Смешать задачу')
  let results = [...modules, ...exceptions, ...tasks]
  results = sort(results)
  return results.slice(0, resultsCount)
}
function sort (items) {
  return items.sort(function (item1, item2) {
    const weight1 = sortingPriority[item1.category] || -1
    const weight2 = sortingPriority[item2.category] || -1
    return weight2 - weight1
  }).sort(function (item1, item2) {
    const matchQuality1 = item1.matchQuality || 0
    const matchQuality2 = item2.matchQuality || 0
    return matchQuality2 - matchQuality1
  })
}
function findIn (elements, term, categoryName) {
  const regExp = new RegExp(helpers.escapeText(term), 'i')
  return elements.reduce(function (results, element) {
    const title = element.title
    const titleMatch = title && title.match(regExp)
    if (titleMatch) {
      const parentResult = serialize({
        id: element.id,
        match: highlight(titleMatch),
        category: categoryName,
        matchQuality: matchQuality(titleMatch)
      }, element.id)
      results.push(parentResult)
    }
    if (element.nodeGroups) {
      for (let {key, nodes} of element.nodeGroups) {
        let matches = findMatchingChildren(nodes, title, term, key)
        if (Object.keys(matches).length > 0) {
          let foundChildren = Object.values(matches)
          foundChildren = foundChildren.map((child) => {
            child.category = 'Child'
            child.label = labels[key]
            return serialize(child, element.id)
          })
          results = results.concat(foundChildren)
        }
      }
    }
    return results
  }, []).filter((result) => !!result)
}
function highlight (match) {
  return match.input.replace(match, `<em>${match[0]}</em>`)
}
function findMatchingChildren (elements, parentId, term, key) {
  const regExp = new RegExp(helpers.escapeText(term), 'i')
  return (elements || []).reduce((acc, element) => {
    if (acc[key + element.id]) { return acc }
    const fullTitle = `${parentId}.${element.id}`
    const fullTitleMatch = !(parentId + '.').match(regExp) && fullTitle.match(regExp)
    const match = element.id && element.id.match(regExp)
    let result = JSON.parse(JSON.stringify(element))
    if (match) {
      result.match = highlight(match)
      result.matchQuality = matchQuality(match)
    } else if (fullTitleMatch) {
      const lastSegment = term.split('.').pop()
      const lastSegmentMatcher = new RegExp(helpers.escapeText(lastSegment), 'i')
      const lastSegmentMatch = element.id.match(lastSegmentMatcher)
      result.matchQuality = matchQuality(lastSegmentMatch)
      result.match = highlight(lastSegmentMatch)
    } else {
      return acc
    }
    acc[key + result.id] = result
    return acc
  }, {})
}
function matchQuality (match) {
  if (!match) { return 0 }
  const textLength = match.input.length
  if (!textLength) { return 0 }
  return match.length / textLength
}
export { getSuggestions }