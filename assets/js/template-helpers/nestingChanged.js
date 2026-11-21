export default function (context, node, options) {
  if (node.nested_context && node.nested_context !== context.nestedContext) {
    context.nestedContext = node.nested_context
    if (context.lastModuleSeenInGroup !== node.nested_context) {
      return options.fn(this)
    }
  } else {
    context.lastModuleSeenInGroup = node.title
  }
}