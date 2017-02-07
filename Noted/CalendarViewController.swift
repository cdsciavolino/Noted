//
//  CalendarViewController.swift
//  Noted
//
//  Created by Chris Sciavolino on 1/20/17.
//  Copyright © 2017 Chris Sciavolino. All rights reserved.
//

import UIKit
import JTAppleCalendar

class CalendarViewController: UIViewController, JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    
    var calendarView: JTAppleCalendarView!          // Scrollable calendar with days
    var weekdayStackView: UIStackView!              // Stack view with days above calendarView
    var notesTextView: UITextView!                  // Displays text from each day's note
    var notesDetailLabel: UILabel!                  // Displays the date above notesTextView
    var doneBarButton: UIBarButtonItem!             // Done button that closes the edit screen for notesTextView
    var todoListBarButton: UIBarButtonItem!         // Button to toggle todoList in tableView
    var monthNames: [String]!                       // Constant with all the full names of each month (cached from formatter)
    let white = UIColor.white                       // Caches white color
    let black = UIColor.black                       // Caches black color
    let grey = UIColor.gray                         // Caches gray color
    
    var dayNotesDictionary: [Date: String] = [:]    // Structure that maps dates to notes (strings)

    override func viewDidLoad() {
        super.viewDidLoad()
        addUIElements()
        self.automaticallyAdjustsScrollViewInsets = false

        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.registerCellViewXib(file: "DateCellView")
        
        // Starts application on the current day
        calendarView.reloadData()
        calendarView.scrollToDate(Date())
        calendarView.selectDates([Date()])
        
        // Format the title screen
        let formatter = DateFormatter()
        let calendar = Calendar.current
        let dayNum = calendar.component(.day, from: Date())
        let monthNum = calendar.component(.month, from: Date())
        let yearNum = calendar.component(.year, from: Date())
        monthNames = formatter.monthSymbols
        let monthString = monthNames?[monthNum-1] ?? "Unknown"
        
        // Notification center observers for keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(CalendarViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CalendarViewController.keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
        
        title = "\(monthString) \(yearNum)"
        notesDetailLabel.text = "\(monthString) \(dayNum), \(yearNum)"
        
        calendarView.cellInset = CGPoint(x: 0, y: 0)
        
        view.backgroundColor = .white
    }
    
    func addUIElements() {
        
        let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        weekdayStackView = UIStackView(frame: CGRect(x: 5, y: 70, width: UIScreen.main.bounds.width-10, height: view.bounds.height * 0.05))

        for index in 0...6 {
            let x_coordinate = 5 + (CGFloat(index) * (UIScreen.main.bounds.width-10)/7.0)
            let weekdayLabel = generateLabel(weekday: daysOfWeek[index], x_coord: x_coordinate)
            weekdayStackView.addArrangedSubview(weekdayLabel)
        }
        
        let border = CALayer()
        let width = CGFloat(0.5)
        border.borderColor = UIColor.darkGray.cgColor
        border.borderWidth = width
        border.frame = CGRect(x: 0, y: weekdayStackView.frame.size.height - width, width: weekdayStackView.frame.size.width, height: width)
        weekdayStackView.layer.addSublayer(border)
        
        weekdayStackView.axis = .horizontal
        weekdayStackView.distribution = .fillEqually
        view.addSubview(weekdayStackView)
        
        calendarView = JTAppleCalendarView(frame: CGRect(x: 5, y: 75 + (view.bounds.height * 0.05), width: UIScreen.main.bounds.width-10, height: view.bounds.height * 0.4))
        view.addSubview(calendarView)
        
        notesDetailLabel = UILabel(frame: CGRect(x: 5, y: 80 + (view.bounds.height * 0.45), width: UIScreen.main.bounds.width-10, height: view.bounds.height * 0.05))
        notesDetailLabel.textColor = .black
        notesDetailLabel.textAlignment = .center
        view.addSubview(notesDetailLabel)
        
        notesTextView = UITextView(frame: CGRect(x: 5, y: 85 + (view.bounds.height * 0.5), width: UIScreen.main.bounds.width-10, height: (view.bounds.height * 0.5) - 90))
        notesTextView.layer.borderWidth = 0.5
        notesTextView.layer.borderColor = UIColor.black.cgColor
        notesTextView.layer.cornerRadius = 5
        view.addSubview(notesTextView)
        
        // done button instantiated but todoButton is shown upon initialization
        doneBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneBarButtonPressed))
        todoListBarButton = UIBarButtonItem(title: "To-Do List", style: .plain, target: self, action: #selector(todoListBarButtonPressed))
        navigationItem.rightBarButtonItem = todoListBarButton
    }
    
    // Generates a label with the string [weekday] and at x_coord
    func generateLabel(weekday: String, x_coord: CGFloat) -> UILabel {
        let weekdayLabel = UILabel(frame: CGRect(x: x_coord, y: 70, width: 60, height: view.bounds.height * 0.05))
        weekdayLabel.text = weekday
        weekdayLabel.textAlignment = .center
        weekdayLabel.textColor = .black
        return weekdayLabel
    }
    
    /** Notification Methods **/
    
    // Bring up the textView to edit with keyboard
    func keyboardWillShow(_ notif: Notification) {
        calendarView.isHidden = true
        weekdayStackView.isHidden = true
        
        let userInfo:NSDictionary = notif.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        let yConstTextField = notesTextView.frame.origin.y - keyboardHeight
        let yConstLabel = notesDetailLabel.frame.origin.y - keyboardHeight
        notesTextView.frame.origin.y = yConstTextField
        notesDetailLabel.frame.origin.y = yConstLabel
        
        navigationItem.rightBarButtonItem = doneBarButton
    }
    
    // Send back the textView after editing finishes
    func keyboardWillHide(_ notif: Notification) {
        calendarView.isHidden = false
        weekdayStackView.isHidden = false
        
        let userInfo = notif.userInfo! as NSDictionary
        let keyboardFrame = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRect = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRect.height
        let yConstTextField = notesTextView.frame.origin.y + keyboardHeight
        let yConstLabel = notesDetailLabel.frame.origin.y + keyboardHeight
        notesTextView.frame.origin.y = yConstTextField
        notesDetailLabel.frame.origin.y = yConstLabel
        
        navigationItem.rightBarButtonItem = todoListBarButton
    }
    
    /** Bar Button Handling Functions **/
    
    func doneBarButtonPressed() {
        notesTextView.resignFirstResponder()
    }
    
    func todoListBarButtonPressed() {
        //TODO: Implement tableview of a todoList in another view
    }
    
    /** Calendar configuration methods **/
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplayCell cell: JTAppleDayCellView, date: Date, cellState: CellState) {
        let dayCell = cell as! DateCellView
        
        // Setup Cell text
        dayCell.dayLabel.text = cellState.text
        if getStringFromDate(date: date) == getStringFromDate(date: Date()) {
            dayCell.todayCircleView.layer.cornerRadius = 20
            dayCell.todayCircleView.isHidden = false
        }
        else {
            dayCell.todayCircleView.isHidden = true
        }
        
        handleCellTextColor(view: cell, cellState: cellState)
        handleCellSelection(view: cell, cellState: cellState)
        
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleDayCellView?, cellState: CellState) {
        notesDetailLabel.text = getStringFromDate(date: date)
        handleCellSelection(view: cell, cellState: cellState)
        handleCellTextColor(view: cell, cellState: cellState)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleDayCellView?, cellState: CellState) {
        let dayInput = notesTextView.text ?? nil
        if dayInput != nil {
            dayNotesDictionary[cellState.date] = dayInput
        }
        handleCellSelection(view: cell, cellState: cellState)
        handleCellTextColor(view: cell, cellState: cellState)
    }
    
    // Function to handle the text color of the calendar
    func handleCellTextColor(view: JTAppleDayCellView?, cellState: CellState) {
        
        guard let dayCell = view as? DateCellView  else {
            return
        }
        
        if cellState.isSelected {
            dayCell.dayLabel.textColor = white
        } else {
            if cellState.dateBelongsTo == .thisMonth {
                dayCell.dayLabel.textColor = black
            } else {
                dayCell.dayLabel.textColor = grey
            }
        }
    }
    
    // Function to handle the calendar selection
    func handleCellSelection(view: JTAppleDayCellView?, cellState: CellState) {
        guard let dayCell = view as? DateCellView  else {
            return
        }
        if cellState.isSelected {
            dayCell.selectionView.layer.cornerRadius =  20
            dayCell.selectionView.isHidden = false
            let dayString = dayNotesDictionary[cellState.date] ?? ""
            notesTextView.text = dayString
        } else {
            dayCell.selectionView.isHidden = true
        }
    }
    
    // returns date in the string form FullMonthName DayNum, YearNum
    func getStringFromDate(date: Date) -> String {
        let calendar = Calendar.current
        let dayNum = calendar.component(.day, from: date)
        let monthNum = calendar.component(.month, from: date)
        let monthString = monthNames[monthNum-1]
        let yearNum = calendar.component(.year, from: date)
        return "\(monthString) \(dayNum), \(yearNum)"
    }
    
    /** Protocol methods in order of declaration **/
    
    /// Asks the data source to return the start and end boundary dates
    /// as well as the calendar to use. You should properly configure
    /// your calendar at this point.
    /// - Parameters:
    ///     - calendar: The JTAppleCalendar view requesting this information.
    /// - returns:
    ///     - ConfigurationParameters instance:
    public func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        
        // TODO: consider better start and end dates for the calendar
        let startDate = formatter.date(from: "01/01/2000")
        let endDate = formatter.date(from: "01/01/2020")
        let parameters = ConfigurationParameters(startDate: startDate!,
                                                 endDate: endDate!,
                                                 numberOfRows: 6,
                                                 calendar: .current,
                                                 generateInDates: .forAllMonths,
                                                 generateOutDates: .tillEndOfGrid,
                                                 firstDayOfWeek: .sunday,
                                                 hasStrictBoundaries: true)
        return parameters
    }
    
}
