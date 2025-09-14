//
//  CustomStringConvertible+prettyDescription.swift
//  SafeConnection
//
//  Created by HanyuChen on 2025/8/29.
//

extension CustomStringConvertible {
    var description: String {
        return prettyDescription()
    }
    
    private func prettyDescription(indent: Int = 0) -> String {
        let indentString = String(repeating: "  ", count: indent)
        let mirror = Mirror(reflecting: self)
        let className = String(describing: type(of: self))
        
        if mirror.children.isEmpty {
            return "\(className)()"
        }
        
        var result = "\(className)(\n"
        
        for child in mirror.children {
            let label = child.label ?? "unknown"
            let value = child.value
            
            result += "\(indentString)  \(label): "
            
            let valueMirror = Mirror(reflecting: value)
            if !valueMirror.children.isEmpty && !(value is String) && !(value is Int) && !(value is Double) && !(value is Bool) {
                if let customValue = value as? any CustomStringConvertible {
                    result += customValue.prettyDescription(indent: indent + 1)
                } else {
                    result += "\(value)"
                }
            } else {
                if value is String {
                    result += "\"\(value)\""
                } else {
                    result += "\(value)"
                }
            }
            result += "\n"
        }
        
        result += "\(indentString))"
        return result
    }
}
