export default function (context, nodeGroup, options) {
  var group = nodeGroup || ''
  if (context.group !== group) {
    delete context.nestedContext
    context.group = group
    return options.fn(this)
  }
}