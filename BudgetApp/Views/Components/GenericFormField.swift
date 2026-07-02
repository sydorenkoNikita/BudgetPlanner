import SwiftUI

struct GenericFormField<Value>: View {
    let label: String
    @Binding var value: Value
    let content: (Binding<Value>) -> AnyView
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            content($value)
        }
    }
}

// MARK: - String Field Variant
struct StringFormField: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        GenericFormField(
            label: label,
            value: $value,
            content: { binding in
                TextField(placeholder, text: binding)
                    .textFieldStyle(.roundedBorder)
                    .eraseToAnyView()
            }
        )
    }
}

// MARK: - Date Field Variant
struct DateFormField: View {
    let label: String
    @Binding var value: Date
    
    var body: some View {
        GenericFormField(
            label: label,
            value: $value,
            content: { binding in
                DatePicker("", selection: binding, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .eraseToAnyView()
            }
        )
    }
}

// MARK: - Preview
#if DEBUG
struct GenericFormField_Previews: PreviewProvider {
    static var previews: some View {
        @State var text = "Sample"
        @State var date = Date.now
        
        VStack(spacing: 20) {
            StringFormField(label: "Name", value: $text, placeholder: "Enter name")
            DateFormField(label: "Date", value: $date)
        }
        .padding()
    }
}
#endif
