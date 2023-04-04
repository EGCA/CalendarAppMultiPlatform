import SwiftUI

struct ContentView: View {
    
    // State variable to keep track of the current month and year
    @State private var currentDate = Date()
    // State variable to keep track of the selected date
    @State private var selectedDate: Date? = nil
    // Dictionary to store events for each date
    @State private var events: [Date: [Event]] = [:]
    
    // State variables to store the user input for a new event
    @State private var newEventTitle: String = ""
    @State private var newEventDate: Date = Date()
    @State private var newEventTime: Date = Date()
    
    @State private var selectedEvent: Event? = nil
    
    // State variable to keep track of whether the new event sheet is presented
    @State private var isPresentingNewEventSheet: Bool = false
    
    // Date formatters for displaying the event date and time
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack {
                // Use a LazyVGrid to display the days of the calendar
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7), spacing: 10) {
                    ForEach(getDatesInMonth(date: currentDate), id: \.self) { date in
                        // Add a Text view to each cell of the LazyVGrid to display the date of each day in the calendar
                        Text(String(Calendar.current.component(.day, from: date)))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(selectedDate == date ? Color.blue : Color.white)
                            .cornerRadius(10)
                            .onTapGesture {
                                selectedDate = date
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                // Add a List view to display events for the selected date
                        List {
                            if let selectedDate = selectedDate {
                                if let eventsForSelectedDate = events[selectedDate] {
                                    ForEach(eventsForSelectedDate, id: \.self) { event in
                                        // Display the title, date, and time for the event
                                        VStack {
                                            HStack {
                                                DatePicker("", selection: Binding(get: {
                                                    event.date
                                                }, set: { newValue in
                                                    events[selectedDate]?.firstIndex(of: event).flatMap {
                                                        events[selectedDate]?[$0].date = newValue
                                                    }
                                                }), displayedComponents: [.date])
                                                DatePicker("", selection: Binding(get: {
                                                    event.time
                                                }, set: { newValue in
                                                    events[selectedDate]?.firstIndex(of: event).flatMap {
                                                        events[selectedDate]?[$0].time = newValue
                                                    }
                                                }), displayedComponents: [.hourAndMinute])
                                                
                                            }

                                            ZStack {
                                                Text(event.title)
                                                    .padding(.horizontal)
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                                
                                                TextField("test", text: Binding(
                                                    get: {
                                                        event.title
                                                    },
                                                    set: { newValue in
                                                        DispatchQueue.main.async {
                                                            events[selectedDate]?.firstIndex(of: event).flatMap { index in
                                                                events[selectedDate]?[index].title = newValue
                                                            }
                                                        }
                                                    }
                                                ))
                                                .textFieldStyle(PlainTextFieldStyle())
                                                .opacity(selectedEvent == event ? 1 : 0)
                                                .padding(.horizontal)
                                            }
                                            .frame(minHeight: 50, maxHeight: .infinity)
                                            .onTapGesture {
                                                selectedEvent = event
                                            }
                                            .onDisappear {
                                                // When editing is complete, deselect the event to dismiss the keyboard
                                                selectedEvent = nil
                                            }
                                            
                                        }
                                    }
                                } else {
                                    Text("No events for this date")
                                }
                            } else {
                                Text("Select a date to view events")
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                
                // Add a Spacer() to push the List view to the top of the view
                Spacer()
            }
            // Add a navigation bar to the top of the app
            .navigationTitle(getMonthYearString(date: currentDate))
            .toolbar {
                ToolbarItemGroup {
                    // Add a button to navigate to the previous month
                    Button(action: {
                        currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate)!
                        selectedDate = nil
                    }) {
                        Image(systemName: "chevron.backward")
                        Text("Previous")
                    }
                    // Add a button to navigate to the next month
                    Button(action: {
                        currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate)!
                        selectedDate = nil
                    }) {
                        Text("Next")
                        Image(systemName: "chevron.forward")
                    }
                    // Add a button to add a new event for the selected date
                    Button(action: {
                        // Create a new event with the user-entered title, date, and time
                        let newEvent = Event(title: newEventTitle, date: newEventDate, time: newEventTime)
                        
                        // Add the new event to the list of events for the selected date
                        if let selectedDate = selectedDate {
                            // If events haven't been initialized for this date yet, create a new array
                            if events[selectedDate] == nil {
                                events[selectedDate] = [newEvent]
                            } else {
                                events[selectedDate]?.append(newEvent)
                            }
                        }
                        
                        // Reset the new event state variables
                        newEventTitle = ""
                        newEventDate = Date()
                        newEventTime = Date()
                        
                        // Dismiss the new event sheet
                        isPresentingNewEventSheet = false
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        // Set the selected date to the current date when the app is launched
        .onAppear {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            selectedDate = Calendar.current.date(from: components)!
        }
    }

    
    // Helper function to get an array of dates for the current month
    private func getDatesInMonth(date: Date) -> [Date] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let startDate = calendar.date(from: components)!
        let range = calendar.range(of: .day, in: .month, for: startDate)!
        
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: startDate) }
    }

    
    // Helper function to get a string representation of a month and year in the format "MMMM yyyy"
    private func getMonthYearString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

// Model struct for an event
struct Event: Hashable {
    var title: String
    var date: Date
    var time: Date
}

struct EditableTextView: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}


