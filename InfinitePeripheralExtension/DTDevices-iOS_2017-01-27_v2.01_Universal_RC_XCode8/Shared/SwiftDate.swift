////
//// SwiftDate.swift
//// SwiftDate
////
//// Copyright (c) 2015 Daniele Margutti
////
//// Permission is hereby granted, free of charge, to any person obtaining a copy
//// of this software and associated documentation files (the "Software"), to deal
//// in the Software without restriction, including without limitation the rights
//// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//// copies of the Software, and to permit persons to whom the Software is
//// furnished to do so, subject to the following conditions:
////
//// The above copyright notice and this permission notice shall be included in
//// all copies or substantial portions of the Software.
////
//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//// THE SOFTWARE.
//
//
//import Foundation
//
////MARK: STRING EXTENSION SHORTCUTS
//
//public extension String {
//    
//    /**
//    Create a new NSDate object with passed custom format string
//    
//    :param: format format as string
//    
//    :returns: a new NSDate instance with parsed date, or nil if it's fail
//    */
//    func toDate(formatString: String!) -> Date? {
//        return Date.date(fromString: self, format: DateFormat.custom(formatString))
//    }
//    
//    /**
//    Create a new NSDate object with passed date format
//    
//    :param: format format
//    
//    :returns: a new NSDate instance with parsed date, or nil if it's fail
//    */
//    func toDate(format: DateFormat) -> Date? {
//        return Date.date(fromString: self, format: format)
//    }
//}
//
////MARK: ACCESS TO DATE COMPONENTS
//
//public extension Date {
//    
//    // Use this as shortcuts for the most common formats for dates
//    static var commonFormats : [String] {
//        return [
//            "yyyy-MM-ddTHH:mm:ssZ", // ISO8601
//            "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'",
//            "yyyy-MM-dd",
//            "h:mm:ss A",
//            "h:mm A",
//            "MM/dd/yyyy",
//            "MMMM d, yyyy",
//            "MMMM d, yyyy LT",
//            "dddd, MMMM D, yyyy LT",
//            "yyyyyy-MM-dd",
//            "yyyy-MM-dd",
//            "GGGG-[W]WW-E",
//            "GGGG-[W]WW",
//            "yyyy-ddd",
//            "HH:mm:ss.SSSS",
//            "HH:mm:ss",
//            "HH:mm",
//            "HH"
//        ]
//    }
//    
//    /// Get the year component of the date
//    var year : Int			{ return components.year! }
//    /// Get the month component of the date
//    var month : Int			{ return components.month! }
//    // Get the week of the month component of the date
//    var weekOfMonth: Int	{ return components.weekOfMonth! }
//    // Get the week of the month component of the date
//    var weekOfYear: Int		{ return components.weekOfYear! }
//    /// Get the weekday component of the date
//    var weekday: Int		{ return components.weekday! }
//    /// Get the weekday ordinal component of the date
//    var weekdayOrdinal: Int	{ return components.weekdayOrdinal! }
//    /// Get the day component of the date
//    var day: Int			{ return components.day! }
//    /// Get the hour component of the date
//    var hour: Int			{ return components.hour! }
//    /// Get the minute component of the date
//    var minute: Int			{ return components.minute! }
//    // Get the second component of the date
//    var second: Int			{ return components.second! }
//    // Get the era component of the date
//    var era: Int			{ return components.era! }
//    // Get the current month name based upon current locale
//    var monthName: String {
//        let dateFormatter = Date.localThreadDateFormatter()
//        dateFormatter.locale = Locale.autoupdatingCurrent
//        return dateFormatter.monthSymbols[month - 1] as String
//    }
//    // Get the current weekday name
//    var weekdayName: String {
//        let dateFormatter = Date.localThreadDateFormatter()
//        dateFormatter.locale = Locale.autoupdatingCurrent
//        dateFormatter.dateFormat = "EEEE"
//        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
//        return dateFormatter.string(from: self)
//    }
//    
//    
//    fileprivate func firstWeekDate()-> (date : Date?, interval: TimeInterval) {
//        // Sunday 1, Monday 2, Tuesday 3, Wednesday 4, Friday 5, Saturday 6
//        var calendar = Calendar.current
//        calendar.firstWeekday = Calendar.current.firstWeekday
//        var startWeek: Date? = nil
//        var duration: TimeInterval = 0
//        
//        (calendar as NSCalendar).range(of: NSCalendar.Unit.weekOfYear, start: &startWeek, interval: &duration, for: self)
//        return (startWeek,duration)
//    }
//    
//    /// Return the first day of the current date's week
//    var firstDayOfWeek : Int {
//        let (date,_) = self.firstWeekDate()
//        return date!.day
//    }
//    
//    /// Return the last day of the week
//    var lastDayOfWeek : Int {
//        let (startWeek,interval) = self.firstWeekDate()
//        let endWeek = startWeek?.addingTimeInterval(interval-1)
//        return endWeek!.day
//    }
//    
//    /// Return the nearest hour of the date
//    var nearestHour:NSInteger{
//        let aTimeInterval = Date.timeIntervalSinceReferenceDate + Double(D_MINUTE) * Double(30);
//        
//        let newDate = Date(timeIntervalSinceReferenceDate:aTimeInterval);
//        let components = (Calendar.current as NSCalendar).components(NSCalendar.Unit.hour, from: newDate);
//        return components.hour!;
//    }
//}
//
////MARK: CREATE AND MANIPULATE DATE COMPONENTS
//
//public extension Date {
//    
//    /**
//    Create a new NSDate instance from passed string with given format
//    
//    :param: string date as string
//    :param: format parse formate.
//    
//    :returns: a new instance of the string
//    */
//    static func date(fromString string: String, format: DateFormat) -> Date? {
//        if string.isEmpty {
//            return nil
//        }
//        
//        let dateFormatter = Date.localThreadDateFormatter()
//        switch format {
//        case .iso8601: // 1972-07-16T08:15:30-05:00
//            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//            dateFormatter.timeZone = TimeZone.autoupdatingCurrent
//            dateFormatter.dateFormat = ISO8601Formatter(fromString: string)
//            return dateFormatter.date(from: string)
//        case .altRSS: // 09 Sep 2011 15:26:08 +0200
//            var formattedString : NSString = string as NSString
//            if formattedString.hasSuffix("Z") {
//                formattedString = formattedString.substring(to: formattedString.length-1) + "GMT"
//            }
//            dateFormatter.dateFormat = "d MMM yyyy HH:mm:ss ZZZ"
//            return dateFormatter.date(from: formattedString as String)
//        case .rss: // Fri, 09 Sep 2011 15:26:08 +0200
//            var formattedString : NSString = string as NSString
//            if formattedString.hasSuffix("Z") {
//                formattedString = formattedString.substring(to: formattedString.length-1) + "GMT"
//            }
//            dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
//            return dateFormatter.date(from: formattedString as String)
//        case .custom(let dateFormat):
//            dateFormatter.dateFormat = dateFormat
//            return dateFormatter.date(from: string)
//        }
//    }
//    
//    /**
//    Attempts to handle all different ISO8601 formatters
//    and returns correct date format for string
//    http://www.w3.org/TR/NOTE-datetime
//    */
//    static func ISO8601Formatter(fromString string: String) -> String {
//        
//        enum IS08601Format: Int {
//            // YYYY (eg 1997)
//            case year = 4
//            
//            // YYYY-MM (eg 1997-07)
//            case yearAndMonth = 7
//            
//            // YYYY-MM-DD (eg 1997-07-16)
//            case completeDate = 10
//            
//            // YYYY-MM-DDThh:mmTZD (eg 1997-07-16T19:20+01:00)
//            case completeDatePlusHoursAndMinutes = 22
//            
//            // YYYY-MM-DDThh:mmTZD (eg 1997-07-16T19:20Z)
//            case completeDatePlusHoursAndMinutesAndZ = 17
//            
//            // YYYY-MM-DDThh:mm:ssTZD (eg 1997-07-16T19:20:30+01:00)
//            case completeDatePlusHoursMinutesAndSeconds = 25
//            
//            // YYYY-MM-DDThh:mm:ssTZD (eg 1997-07-16T19:20:30Z)
//            case completeDatePlusHoursAndMinutesAndSecondsAndZ = 20
//            
//            // YYYY-MM-DDThh:mm:ss.sTZD (eg 1997-07-16T19:20:30.45+01:00)
//            case completeDatePlusHoursMinutesSecondsAndDecimalFractionOfSecond = 28
//            
//            // YYYY-MM-DDThh:mm:ss.sTZD (eg 1997-07-16T19:20:30.45Z)
//            case completeDatePlusHoursMinutesSecondsAndDecimalFractionOfSecondAndZ = 23
//        }
//        
//        var dateFormatter = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
//        
//        if let dateStringCount = IS08601Format(rawValue: string.characters.count) {
//            switch dateStringCount {
//            case .year:
//                dateFormatter = "yyyy"
//            case .yearAndMonth:
//                dateFormatter = "yyyy-MM"
//            case .completeDate:
//                dateFormatter = "yyyy-MM-dd"
//            case .completeDatePlusHoursAndMinutes, .completeDatePlusHoursAndMinutesAndZ:
//                dateFormatter = "yyyy-MM-dd'T'HH:mmZ"
//            case .completeDatePlusHoursMinutesAndSeconds, .completeDatePlusHoursAndMinutesAndSecondsAndZ:
//                dateFormatter = "yyyy-MM-dd'T'HH:mm:ssZ"
//            case .completeDatePlusHoursMinutesSecondsAndDecimalFractionOfSecond, .completeDatePlusHoursMinutesSecondsAndDecimalFractionOfSecondAndZ:
//                dateFormatter = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
//            }
//        }
//        return dateFormatter
//    }
//    
//    /**
//    Create a new NSDate instance based on refDate (if nil uses current date) and set components
//    
//    :param: refDate reference date instance (nil to use NSDate())
//    :param: year    year component (nil to leave it untouched)
//    :param: month   month component (nil to leave it untouched)
//    :param: day     day component (nil to leave it untouched)
//    :param: tz      time zone component (it's the abbreviation of NSTimeZone, like 'UTC' or 'GMT+2', nil to use current time zone)
//    
//    :returns: a new NSDate with components changed according to passed params
//    */
//    static func date(refDate: Date?, year: Int?, month: Int?, day: Int?, tz: String?) -> Date {
//        let referenceDate = refDate ?? Date()
//        return referenceDate.set(year: year, month: month, day: day, hour: 0, minute: 0, second: 0, tz: tz)
//    }
//    
//    /**
//    Create a new NSDate instance based on refDate (if nil uses current date) and set components
//    
//    :param: refDate reference date instance (nil to use NSDate())
//    :param: year    year component (nil to leave it untouched)
//    :param: month   month component (nil to leave it untouched)
//    :param: day     day component (nil to leave it untouched)
//    :param: hour    hour component (nil to leave it untouched)
//    :param: minute  minute component (nil to leave it untouched)
//    :param: second  second component (nil to leave it untouched)
//    :param: tz      time zone component (it's the abbreviation of NSTimeZone, like 'UTC' or 'GMT+2', nil to use current time zone)
//    
//    :returns: a new NSDate with components changed according to passed params
//    */
//    static func date(refDate: Date?, year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, tz: String?) -> Date {
//        let referenceDate = refDate ?? Date()
//        return referenceDate.set(year: year, month: month, day: day, hour: hour, minute: minute, second: second, tz: tz)
//    }
//    
//    /**
//    Return a new NSDate instance with the current date and time set to 00:00:00
//    
//    :param: tz optional timezone abbreviation
//    
//    :returns: a new NSDate instance of the today's date
//    */
//    static func today(_ tz: String? = nil) -> Date! {
//        let nowDate = Date()
//        return Date.date(refDate: nowDate, year: nowDate.year, month: nowDate.month, day: nowDate.day, tz: tz)
//    }
//    
//    /**
//    Return a new NSDate istance with the current date minus one day
//    
//    :param: tz optional timezone abbreviation
//    
//    :returns: a new NSDate instance which represent yesterday's date
//    */
//    static func yesterday(_ tz: String? = nil) -> Date! {
//        return today(tz)-1.day
//    }
//    
//    /**
//    Return a new NSDate istance with the current date plus one day
//    
//    :param: tz optional timezone abbreviation
//    
//    :returns: a new NSDate instance which represent tomorrow's date
//    */
//    static func tomorrow(_ tz: String? = nil) -> Date! {
//        return today(tz)+1.day
//    }
//    
//    /**
//    Individual set single component of the current date instance
//    
//    :param: year   a non-nil value to change the year component of the instance
//    :param: month  a non-nil value to change the month component of the instance
//    :param: day    a non-nil value to change the day component of the instance
//    :param: hour   a non-nil value to change the hour component of the instance
//    :param: minute a non-nil value to change the minute component of the instance
//    :param: second a non-nil value to change the second component of the instance
//    :param: tz     a non-nil value (timezone abbreviation string as for NSTimeZone) to change the timezone component of the instance
//    
//    :returns: a new NSDate instance with changed values
//    */
//    func set(year: Int?=nil, month: Int?=nil, day: Int?=nil, hour: Int?=nil, minute: Int?=nil, second: Int?=nil, tz: String?=nil) -> Date! {
//        var components = self.components
//        components.year = year ?? self.year
//        components.month = month ?? self.month
//        components.day = day ?? self.day
//        components.hour = hour ?? self.hour
//        components.minute = minute ?? self.minute
//        components.second = second ?? self.second
//        (components as NSDateComponents).timeZone = (tz != nil ? TimeZone(abbreviation: tz!) : TimeZone.current)
//        return Calendar.current.date(from: components)
//    }
//    
//    /**
//    Allows you to set individual date components by passing an array of components name and associated values
//    
//    :param: componentsDict components dict. Accepted keys are year,month,day,hour,minute,second
//    
//    :returns: a new date instance with altered components according to passed dictionary
//    */
//    @available(iOS 8.0, *)
//    func set(componentsDict: [String:Int]!) -> Date? {
//        if componentsDict.count == 0 {
//            return self
//        }
//        let components = self.components
//        for (thisComponent,value) in componentsDict {
//            let unit : NSCalendar.Unit = thisComponent._sdToCalendarUnit()
//            (components as NSDateComponents).setValue(value, forComponent: unit);
//        }
//        return Calendar.current.date(from: components)
//    }
//    
//    /**
//    Allows you to set a single component by passing it's name (year,month,day,hour,minute,second are accepted).
//    Please note: this method return a new immutable NSDate instance (NSDate are immutable, damn!). So while you
//    can chain multiple set calls, if you need to alter more than one component see the method above which accept
//    different params.
//    
//    :param: name  the name of the component to alter (year,month,day,hour,minute,second are accepted)
//    :param: value the value of the component
//    
//    :returns: a new date instance
//    */
//    @available(iOS 8.0, *)
//    func set(_ name : String!, value : Int!) -> Date? {
//        let unit : NSCalendar.Unit = name._sdToCalendarUnit()
//        if unit == [] {
//            return nil
//        }
//        let components = self.components
//        (components as NSDateComponents).setValue(value, forComponent: unit);
//        return Calendar.current.date(from: components)
//    }
//    
//    /**
//    Add or subtract (via negative values) components from current date instance
//    
//    :param: years   nil or +/- years to add or subtract from date
//    :param: months  nil or +/- months to add or subtract from date
//    :param: weeks   nil or +/- weeks to add or subtract from date
//    :param: days    nil or +/- days to add or subtract from date
//    :param: hours   nil or +/- hours to add or subtract from date
//    :param: minutes nil or +/- minutes to add or subtract from date
//    :param: seconds nil or +/- seconds to add or subtract from date
//    
//    :returns: a new NSDate instance with changed values
//    */
//    func add(years: Int=0, months: Int=0, weeks: Int=0, days: Int=0,hours: Int=0,minutes: Int=0,seconds: Int=0) -> Date {
//        var components = DateComponents()
//        components.year = years
//        components.month = months
//        components.weekOfYear = weeks
//        components.day = days
//        components.hour = hours
//        components.minute = minutes
//        components.second = seconds
//        return self.addComponents(components)
//    }
//    
//    /**
//    Add/substract (based on sign) specified component with value
//    
//    :param: name  component name (year,month,day,hour,minute,second)
//    :param: value value of the component
//    
//    :returns: new date with altered component
//    */
//    @available(iOS 8.0, *)
//    func add(_ name : String!, value : Int!) -> Date? {
//        let unit : NSCalendar.Unit = name._sdToCalendarUnit()
//        if unit == [] {
//            return nil
//        }
//        let components = DateComponents()
//        (components as NSDateComponents).setValue(value, forComponent: unit);
//        return self.addComponents(components)
//    }
//    
//    /**
//    Add value specified by components in passed dictionary to the current date
//    
//    :param: componentsDict dictionary of the component to alter with value (year,month,day,hour,minute,second)
//    
//    :returns: new date with altered components
//    */
//    @available(iOS 8.0, *)
//    func add(componentsDict: [String:Int]!) -> Date? {
//        if componentsDict.count == 0 {
//            return self
//        }
//        let components = DateComponents()
//        for (thisComponent,value) in componentsDict {
//            let unit : NSCalendar.Unit = thisComponent._sdToCalendarUnit()
//            (components as NSDateComponents).setValue(value, forComponent: unit);
//        }
//        return self.addComponents(components)
//    }
//}
//
////MARK: TIMEZONE UTILITIES
//
//public extension Date {
//    /**
//    Return a new NSDate in UTC format from the current system timezone
//    
//    :returns: a new NSDate instance
//    */
//    func toUTC() -> Date {
//        let tz : TimeZone = TimeZone.autoupdatingCurrent
//        let secs : Int = tz.secondsFromGMT(for: self)
//        return Date(timeInterval: TimeInterval(secs), since: self)
//    }
//    
//    /**
//    Convert an UTC NSDate instance to a local time NSDate (note: NSDate object does not contains info about the timezone!)
//    
//    :returns: a new NSDate instance
//    */
//    func toLocalTime() -> Date {
//        let tz : TimeZone = TimeZone.autoupdatingCurrent
//        let secs : Int = -tz.secondsFromGMT(for: self)
//        return Date(timeInterval: TimeInterval(secs), since: self)
//    }
//    
//    /**
//    Convert an UTC NSDate instance to passed timezone (note: NSDate object does not contains info about the timezone!)
//    
//    :param: abbreviation abbreviation of the time zone
//    
//    :returns: a new NSDate instance
//    */
//    func toTimezone(_ abbreviation : String!) -> Date? {
//        let tz : TimeZone? = TimeZone(abbreviation: abbreviation)
//        if tz == nil {
//            return nil
//        }
//        let secs : Int = tz!.secondsFromGMT(for: self)
//        return Date(timeInterval: TimeInterval(secs), since: self)
//    }
//}
//
////MARK: COMPARE DATES
//
//public extension Date {
//    
//    /**
//    Return the difference in terms of NSDateComponents between two dates.
//    
//    - parameter toDate:    other date to compare
//    - parameter unitFlags: components to compare
//    
//    - returns: result of comparision as NSDateComponents
//    */
//    func difference(_ toDate: Date, unitFlags: NSCalendar.Unit) -> DateComponents {
//        let calendar = Calendar.current
//        let components = (calendar as NSCalendar).components(unitFlags, from: self, to: toDate, options: NSCalendar.Options(rawValue: 0))
//        return components
//    }
//    
//    /**
//    *  This function is deprecated. See -difference
//    */
//    @available(*, deprecated: 1.2, obsoleted: 1.4, renamed: "difference")
//    func secondsAfterDate(_ date: Date) -> Int {
//        let interval = self.timeIntervalSince(date)
//        return Int(interval)
//    }
//    
//    /**
//    *  This function is deprecated. See -difference
//    */
//    @available(*, deprecated: 1.2, obsoleted: 1.4, renamed: "difference")
//    func secondsBeforeDate(_ date: Date) -> Int {
//        let interval = date.timeIntervalSince(self)
//        return Int(interval)
//    }
//    
//    /**
//    *  This function is deprecated. See -difference
//    */
//    @available(*, deprecated: 1.2, obsoleted: 1.4, renamed: "difference")
//    func minutesAfterDate(_ date: Date) -> Int {
//        let interval = self.timeIntervalSince(date)
//        return Int(interval / TimeInterval(D_MINUTE))
//    }
//    
//    /**
//    *  This function is deprecated. See -difference
//    */
//    @available(*, deprecated: 1.2, obsoleted: 1.4, renamed: "difference")
//    func minutesBeforeDate(_ date: Date) -> Int {
//        let interval = date.timeIntervalSince(self)
//        return Int(interval / TimeInterval(D_MINUTE))
//    }
//    
//    /**
//    *  This function is deprecated. See -difference
//    */
//    @available(*, deprecated: 1.2, obsoleted: 1.4, renamed: "difference")
//    func hoursAfterDate(_ date: Date) -> Int {
//        let interval = self.timeIntervalSince(date)
//        return Int(interval / TimeInterval(D_HOUR))
//    }
//    
//    /**
//    *  This function is deprecated. See -difference
//    */
//    @available(*, deprecated: 1.2, obsoleted: 1.4, renamed: "difference")
//    func hoursBeforeDate(_ date: Date) -> Int {
//        let interval = date.timeIntervalSince(self)
//        return Int(interval / TimeInterval(D_HOUR))
//    }
//    
//    /**
//    *  This function is deprecated. See -difference
//    */
//    @available(*, deprecated: 1.2, obsoleted: 1.4, renamed: "difference")
//    func daysAfterDate(_ date: Date) -> Int {
//        let interval = self.timeIntervalSince(date)
//        return Int(interval / TimeInterval(D_DAY))
//    }
//    
//    /**
//    *  This function is deprecated. See -difference
//    */
//    @available(*, deprecated: 1.2, obsoleted: 1.4, renamed: "difference")
//    func daysBeforeDate(_ date: Date) -> Int {
//        let interval = date.timeIntervalSince(self)
//        return Int(interval / TimeInterval(D_DAY))
//    }
//    
//    /**
//    Compare two dates and return true if they are equals
//    
//    :param: date       date to compare with
//    :param: ignoreTime true to ignore time of the date
//    
//    :returns: true if two dates are equals
//    */
//    func isEqualToDate(_ date: Date, ignoreTime: Bool) -> Bool {
//        if ignoreTime {
//            let comp1 = Date.components(fromDate: self)
//            let comp2 = Date.components(fromDate: date)
//            return ((comp1!.era == comp2!.era) && (comp1!.year == comp2!.year) && (comp1!.month == comp2!.month) && (comp1!.day == comp2!.day))
//        } else {
//            return (self == date)
//        }
//    }
//    
//    /**
//    Return true if given date's time in passed range
//    
//    :param: minTime min time interval (by default format is "HH:mm", but you can specify your own format in format parameter)
//    :param: maxTime max time interval (by default format is "HH:mm", but you can specify your own format in format parameter)
//    :param: format  nil or a valid format string used to parse minTime and maxTime from their string representation (when nil HH:mm is used)
//    
//    :returns: true if date's time component falls into given range
//    */
//    func isInTimeRange(_ minTime: String!, maxTime: String!, format: String?) -> Bool {
//        let dateFormatter = Date.localThreadDateFormatter()
//        dateFormatter.dateFormat = format ?? "HH:mm"
//        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//        let minTimeDate = dateFormatter.date(from: minTime)
//        let maxTimeDate = dateFormatter.date(from: maxTime)
//        if minTimeDate == nil || maxTimeDate == nil {
//            return false
//        }
//        let inBetween = (self.compare(minTimeDate!) == ComparisonResult.orderedDescending &&
//            self.compare(maxTimeDate!) == ComparisonResult.orderedAscending)
//        return inBetween
//    }
//    
//    /**
//    Return true if the date's year is a leap year
//    
//    :returns: true if date's year is a leap year
//    */
//    func isLeapYear() -> Bool {
//        let year = self.year
//        return year % 400 == 0 ? true : ((year % 4 == 0) && (year % 100 != 0))
//    }
//    
//    /**
//    Return the number of days in current date's month
//    
//    :returns: number of days of the month
//    */
//    func monthDays () -> Int {
//        return (Calendar.current as NSCalendar).range(of: NSCalendar.Unit.day, in: NSCalendar.Unit.month, for: self).length
//    }
//    
//    /**
//    True if the date is the current date
//    
//    :returns: true if date is today
//    */
//    func isToday() -> Bool {
//        return self.isEqualToDate(Date(), ignoreTime: true)
//    }
//    
//    /**
//    True if the date is the current date plus one day (tomorrow)
//    
//    :returns: true if date is tomorrow
//    */
//    func isTomorrow() -> Bool {
//        return self.isEqualToDate(Date()+1.day, ignoreTime:true)
//    }
//    
//    /**
//    True if the date is the current date minus one day (yesterday)
//    
//    :returns: true if date is yesterday
//    */
//    func isYesterday() -> Bool {
//        return self.isEqualToDate(Date()-1.day, ignoreTime:true)
//    }
//    
//    /**
//    Return true if the date falls into the current week
//    
//    :returns: true if date is inside the current week days range
//    */
//    func isThisWeek() -> Bool {
//        return self.isSameWeekOf(Date())
//    }
//    
//    /**
//    Return true if the date falls into the current month
//    
//    :returns: true if date is inside the current month
//    */
//    func isThisMonth() -> Bool {
//        return self.isSameMonthOf(Date())
//    }
//    
//    /**
//    Return true if the date falls into the current year
//    
//    :returns: true if date is inside the current year
//    */
//    func isThisYear() -> Bool {
//        return self.isSameYearOf(Date())
//    }
//    
//    /**
//    Return true if the date is in the same week of passed date
//    
//    :param: date date to compare with
//    
//    :returns: true if both dates falls in the same week
//    */
//    func isSameWeekOf(_ date: Date) -> Bool {
//        let comp1 = Date.components(fromDate: self)
//        let comp2 = Date.components(fromDate: date)
//        // Must be same week. 12/31 and 1/1 will both be week "1" if they are in the same week
//        if comp1?.weekOfYear != comp2?.weekOfYear {
//            return false
//        }
//        // Must have a time interval under 1 week
//        let weekInSeconds = TimeInterval(D_WEEK)
//        return abs(self.timeIntervalSince(date)) < weekInSeconds
//    }
//    
//    /**
//    Return the first day of the passed date's week (Sunday)
//    
//    :returns: NSDate with the date of the first day of the week
//    */
//    func dateAtWeekStart() -> Date {
//        let flags : NSCalendar.Unit = [NSCalendar.Unit.year,NSCalendar.Unit.month ,
//            NSCalendar.Unit.weekOfYear,
//            NSCalendar.Unit.weekday]
//        var components = (Calendar.current as NSCalendar).components(flags, from: self)
//        components.weekday = 1 // Sunday
//        components.hour = 0
//        components.minute = 0
//        components.second = 0
//        return Calendar.current.date(from: components)!
//    }
//    
//    /// Return a date which represent the beginning of the current day (at 00:00:00)
//    var beginningOfDay: Date {
//        return set(hour: 0, minute: 0, second: 0)
//    }
//    
//    /// Return a date which represent the end of the current day (at 23:59:59)
//    var endOfDay: Date {
//        return set(hour: 23, minute: 59, second: 59)
//    }
//    
//    /// Return the first day of the month of the current date
//    var beginningOfMonth: Date {
//        return set(day: 1, hour: 0, minute: 0, second: 0)
//    }
//    
//    /// Return the last day of the month of the current date
//    var endOfMonth: Date {
//        let lastDay = (Calendar.current as NSCalendar).range(of: .day, in: .month, for: self).length
//        return set(day: lastDay, hour: 23, minute: 59, second: 59)
//    }
//    
//    /// Returns true if the date is in the same month of passed date
//    func isSameMonthOf(_ date: Date) -> Bool {
//        return self >= date.beginningOfMonth && self <= date.endOfMonth
//    }
//    
//    /// Return the first day of the year of the current date
//    var beginningOfYear: Date {
//        return set(month: 1, day: 1, hour: 0, minute: 0, second: 0)
//    }
//    
//    /// Return the last day of the year of the current date
//    var endOfYear: Date {
//        return set(month: 12, day: 31, hour: 23, minute: 59, second: 59)
//    }
//    
//    /// Returns true if the date is in the same year of passed date
//    func isSameYearOf(_ date: Date) -> Bool {
//        return self >= date.beginningOfYear && self <= date.endOfYear
//    }
//    
//    /**
//    Return true if current date's day is not a weekend day
//    
//    :returns: true if date's day is a week day, not a weekend day
//    */
//    func isWeekday() -> Bool {
//        return !self.isWeekend()
//    }
//    
//    /**
//    Return true if the date is the weekend
//    
//    :returns: true or false
//    */
//    func isWeekend() -> Bool {
//        let range = (Calendar.current as NSCalendar).maximumRange(of: NSCalendar.Unit.weekday)
//        return (self.weekday == range.location || self.weekday == range.length)
//    }
//    
//}
//
////MARK: CONVERTING DATE TO STRING
//
//public extension Date {
//    
//    /**
//    Return a formatted string with passed style for date and time
//    
//    :param: dateStyle    style of the date component into the output string
//    :param: timeStyle    style of the time component into the output string
//    :param: relativeDate true to use relative date style
//    
//    :returns: string representation of the date
//    */
//    public func toString(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, relativeDate: Bool = false) -> String {
//        let dateFormatter = Date.localThreadDateFormatter()
//        dateFormatter.dateStyle = dateStyle
//        dateFormatter.timeStyle = timeStyle
//        dateFormatter.doesRelativeDateFormatting = relativeDate
//        return dateFormatter.string(from: self)
//    }
//    
//    /**
//    Return a new string which represent the NSDate into passed format
//    
//    :param: format format of the output string. Choose one of the available format or use a custom string
//    
//    :returns: a string with formatted date
//    */
//    public func toString(format: DateFormat) -> String {
//        var dateFormat: String
//        switch format {
//        case .iso8601:
//            dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
//        case .rss:
//            dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
//        case .altRSS:
//            dateFormat = "d MMM yyyy HH:mm:ss ZZZ"
//        case .custom(let string):
//            dateFormat = string
//        }
//        let dateFormatter = Date.localThreadDateFormatter()
//        dateFormatter.dateFormat = dateFormat
//        return dateFormatter.string(from: self)
//    }
//    
//    /**
//    Return an ISO8601 formatted string from the current date instance
//    
//    :returns: string with date in ISO8601 format
//    */
//    public func toISOString() -> String {
//        let dateFormatter = Date.localThreadDateFormatter()
//        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
//        return dateFormatter.string(from: self) + "Z"
//    }
//    
//    /**
//    Return a relative string which represent the date instance
//    
//    :param: fromDate    comparison date (by default is the current NSDate())
//    :param: abbreviated true to use abbreviated unit forms (ie. "ys" instead of "years")
//    :param: maxUnits    max detail units to print (ie. "1 hour 47 minutes" is maxUnit=2, "1 hour" is maxUnit=1)
//    
//    :returns: formatted string
//    */
//    public func toRelativeString(_ fromDate: Date = Date(), abbreviated : Bool = false, maxUnits: Int = 1) -> String {
//        let seconds = fromDate.timeIntervalSince(self)
//        if fabs(seconds) < 1 {
//            return "just now"._sdLocalize
//        }
//        
//        let significantFlags : NSCalendar.Unit = Date.componentFlags()
//        let components = (Calendar.current as NSCalendar).components(significantFlags, from: fromDate, to: self, options: [])
//        
//        var string = String()
//        //var isApproximate:Bool = false
//        var numberOfUnits:Int = 0
//        let unitList : [String] = ["year", "month", "weekOfYear", "day", "hour", "minute", "second"]
//        for unitName in unitList {
//            let unit : NSCalendar.Unit = unitName._sdToCalendarUnit()
//            if ((significantFlags.rawValue & unit.rawValue) != 0) &&
//                (_sdCompareCalendarUnit(NSCalendar.Unit.second, other: unit) != .orderedDescending) {
//                    let number:NSNumber = NSNumber(value: fabsf(components.value(for: unitName)!.floatValue) as Float)
//                    if Bool(number.intValue) {
//                        let singular = (number.uintValue == 1)
//                        let suffix = String(format: "%@ %@", arguments: [number, _sdLocalizeStringForValue(singular, unit: unit, abbreviated: abbreviated)])
//                        if string.isEmpty {
//                            string = suffix
//                        } else if numberOfUnits < maxUnits {
//                            string += String(format: " %@", arguments: [suffix])
//                        } else {
//                            //	isApproximate = true
//                        }
//                        numberOfUnits += 1
//                    }
//            }
//        }
//        
//        /*if string.isEmpty == false {
//        if seconds > 0 {
//        string = String(format: "%@ %@", arguments: [string, "ago"._sdLocalize])
//        } else {
//        string = String(format: "%@ %@", arguments: [string, "from now"._sdLocalize])
//        }
//        
//        if (isApproximate) {
//        string = String(format: "about %@", arguments: [string])
//        }
//        }*/
//        return string
//    }
//    
//    /**
//    Return a string representation of the date where both date and time are in short style format
//    
//    :returns: date's string representation
//    */
//    public func toShortString() -> String {
//        return toString(dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short)
//    }
//    
//    /**
//    Return a string representation of the date where both date and time are in medium style format
//    
//    :returns: date's string representation
//    */
//    public func toMediumString() -> String {
//        return toString(dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.medium)
//    }
//    
//    /**
//    Return a string representation of the date where both date and time are in long style format
//    
//    :returns: date's string representation
//    */
//    public func toLongString() -> String {
//        return toString(dateStyle: DateFormatter.Style.long, timeStyle: DateFormatter.Style.long)
//    }
//    
//    /**
//    Return a string representation of the date with only the date in short style format (no time)
//    
//    :returns: date's string representation
//    */
//    public func toShortDateString() -> String {
//        return toString(dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.none)
//    }
//    
//    /**
//    Return a string representation of the date with only the time in short style format (no date)
//    
//    :returns: date's string representation
//    */
//    public func toShortTimeString() -> String {
//        return toString(dateStyle: DateFormatter.Style.none, timeStyle: DateFormatter.Style.short)
//    }
//    
//    /**
//    Return a string representation of the date with only the date in medium style format (no date)
//    
//    :returns: date's string representation
//    */
//    public func toMediumDateString() -> String {
//        return toString(dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.none)
//    }
//    
//    /**
//    Return a string representation of the date with only the time in medium style format (no date)
//    
//    :returns: date's string representation
//    */
//    public func toMediumTimeString() -> String {
//        return toString(dateStyle: DateFormatter.Style.none, timeStyle: DateFormatter.Style.medium)
//    }
//    
//    /**
//    Return a string representation of the date with only the date in long style format (no date)
//    
//    :returns: date's string representation
//    */
//    public func toLongDateString() -> String {
//        return toString(dateStyle: DateFormatter.Style.long, timeStyle: DateFormatter.Style.none)
//    }
//    
//    /**
//    Return a string representation of the date with only the time in long style format (no date)
//    
//    :returns: date's string representation
//    */
//    public func toLongTimeString() -> String {
//        return toString(dateStyle: DateFormatter.Style.none, timeStyle: DateFormatter.Style.long)
//    }
//    
//}
//
////MARK: PRIVATE ACCESSORY METHODS
//
//private extension Date {
//    
//    static func components(fromDate: Date) -> DateComponents! {
//        return (Calendar.current as NSCalendar).components(Date.componentFlags(), from: fromDate)
//    }
//    
//    func addComponents(_ components: DateComponents) -> Date {
//        let cal = Calendar.current
//        return (cal as NSCalendar).date(byAdding: components, to: self, options: [])!
//    }
//    
//    static func componentFlags() -> NSCalendar.Unit {
//        return [NSCalendar.Unit.era ,
//            NSCalendar.Unit.year ,
//            NSCalendar.Unit.month ,
//            NSCalendar.Unit.day,
//            NSCalendar.Unit.weekOfYear,
//            NSCalendar.Unit.hour ,
//            NSCalendar.Unit.minute ,
//            NSCalendar.Unit.second ,
//            NSCalendar.Unit.weekday ,
//            NSCalendar.Unit.weekdayOrdinal,
//            NSCalendar.Unit.weekOfYear]
//    }
//    
//    /// Return the NSDateComponents which represent current date
//    var components: DateComponents {
//        return  (Calendar.current as NSCalendar).components(Date.componentFlags(), from: self)
//    }
//    
//    /**
//    This function uses NSThread dictionary to store and retrive a thread-local object, creating it if it has not already been created
//    
//    :param: key    identifier of the object context
//    :param: create create closure that will be invoked to create the object
//    
//    :returns: a cached instance of the object
//    */
//    static func cachedObjectInCurrentThread<T: AnyObject>(_ key: String, create: () -> T) -> T {
//        if let threadDictionary = Thread.current.threadDictionary as NSMutableDictionary? {
//            if let cachedObject = threadDictionary[key] as! T? {
//                return cachedObject
//            } else {
//                let newObject = create()
//                threadDictionary[key] = newObject
//                return newObject
//            }
//        } else {
//            assert(false, "Current NSThread dictionary is nil. This should never happens, we will return a new instance of the object on each call")
//            return create()
//        }
//    }
//    
//    /**
//    Return a thread-cached NSDateFormatter instance
//    
//    :returns: instance of NSDateFormatter
//    */
//    static func localThreadDateFormatter() -> DateFormatter {
//        return Date.cachedObjectInCurrentThread("com.library.swiftdate.dateformatter") {
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
//            return dateFormatter
//        }
//    }
//}
//
////MARK: RELATIVE NSDATE CONVERSION PRIVATE METHODS
//
//private extension Date {
//    func _sdCompareCalendarUnit(_ unit:NSCalendar.Unit, other:NSCalendar.Unit) -> ComparisonResult {
//        let nUnit = _sdNormalizedCalendarUnit(unit)
//        let nOther = _sdNormalizedCalendarUnit(other)
//        
//        if (nUnit == NSCalendar.Unit.weekOfYear) != (nOther == NSCalendar.Unit.weekOfYear) {
//            if nUnit == NSCalendar.Unit.weekOfYear {
//                switch nUnit {
//                case NSCalendar.Unit.year, NSCalendar.Unit.month:
//                    return .orderedAscending
//                default:
//                    return .orderedDescending
//                }
//            } else {
//                switch nOther {
//                case NSCalendar.Unit.year, NSCalendar.Unit.month:
//                    return .orderedDescending
//                default:
//                    return .orderedAscending
//                }
//            }
//        } else {
//            if nUnit.rawValue > nOther.rawValue {
//                return .orderedAscending
//            } else if (nUnit.rawValue < nOther.rawValue) {
//                return .orderedDescending
//            } else {
//                return .orderedSame
//            }
//        }
//    }
//    
//    func _sdNormalizedCalendarUnit(_ unit:NSCalendar.Unit) -> NSCalendar.Unit {
//        switch unit {
//        case NSCalendar.Unit.weekOfMonth, NSCalendar.Unit.weekOfYear:
//            return NSCalendar.Unit.weekOfYear
//        case NSCalendar.Unit.weekday, NSCalendar.Unit.weekdayOrdinal:
//            return NSCalendar.Unit.day
//        default:
//            return unit;
//        }
//    }
//    
//    
//    func _sdLocalizeStringForValue(_ singular : Bool, unit: NSCalendar.Unit, abbreviated: Bool = false) -> String {
//        var toTranslate : String = ""
//        switch unit {
//            
//        case NSCalendar.Unit.year where singular:		toTranslate = (abbreviated ? "yr" : "year")
//        case NSCalendar.Unit.year where !singular:		toTranslate = (abbreviated ? "yrs" : "years")
//            
//        case NSCalendar.Unit.month where singular:		toTranslate = (abbreviated ? "mo" : "month")
//        case NSCalendar.Unit.month where !singular:		toTranslate = (abbreviated ? "mos" : "months")
//            
//        case NSCalendar.Unit.weekOfYear where singular:	toTranslate = (abbreviated ? "wk" : "week")
//        case NSCalendar.Unit.weekOfYear where !singular: toTranslate = (abbreviated ? "wks" : "weeks")
//            
//        case NSCalendar.Unit.day where singular:			toTranslate = "day"
//        case NSCalendar.Unit.day where !singular:		toTranslate = "days"
//            
//        case NSCalendar.Unit.hour where singular:		toTranslate = (abbreviated ? "hr" : "hour")
//        case NSCalendar.Unit.hour where !singular:		toTranslate = (abbreviated ? "hrs" : "hours")
//            
//        case NSCalendar.Unit.minute where singular:		toTranslate = (abbreviated ? "min" : "minute")
//        case NSCalendar.Unit.minute where !singular:		toTranslate = (abbreviated ? "mins" : "minutes")
//            
//        case NSCalendar.Unit.second where singular:		toTranslate = (abbreviated ? "s" : "second")
//        case NSCalendar.Unit.second where !singular:		toTranslate = (abbreviated ? "s" : "seconds")
//            
//        default:													toTranslate = ""
//        }
//        return toTranslate._sdLocalize
//    }
//    
//    func localizedSimpleStringForComponents(_ components:DateComponents) -> String {
//        if (components.year == -1) {
//            return "last year"._sdLocalize
//        } else if (components.month == -1 && components.year == 0) {
//            return "last month"._sdLocalize
//        } else if (components.weekOfYear == -1 && components.year == 0 && components.month == 0) {
//            return "last week"._sdLocalize
//        } else if (components.day == -1 && components.year == 0 && components.month == 0 && components.weekOfYear == 0) {
//            return "yesterday"._sdLocalize
//        } else if (components == 1) {
//            return "next year"._sdLocalize
//        } else if (components.month == 1 && components.year == 0) {
//            return "next month"._sdLocalize
//        } else if (components.weekOfYear == 1 && components.year == 0 && components.month == 0) {
//            return "next week"._sdLocalize
//        } else if (components.day == 1 && components.year == 0 && components.month == 0 && components.weekOfYear == 0) {
//            return "tomorrow"._sdLocalize
//        }
//        return ""
//    }
//}
//
////MARK: OPERATIONS WITH DATES (==,!=,<,>,<=,>=)
//
//extension Date : Comparable {}
//
//public func == (left: Date, right: Date) -> Bool {
//    return (left.compare(right) == ComparisonResult.orderedSame)
//}
//
//public func != (left: Date, right: Date) -> Bool {
//    return !(left == right)
//}
//
//public func < (left: Date, right: Date) -> Bool {
//    return (left.compare(right) == ComparisonResult.orderedAscending)
//}
//
//public func > (left: Date, right: Date) -> Bool {
//    return (left.compare(right) == ComparisonResult.orderedDescending)
//}
//
//public func <= (left: Date, right: Date) -> Bool {
//    return !(left > right)
//}
//
//public func >= (left: Date, right: Date) -> Bool {
//    return !(left < right)
//}
//
////MARK: ARITHMETIC OPERATIONS WITH DATES (-,-=,+,+=)
//
//public func - (left : Date, right: TimeInterval) -> Date {
//    return left.addingTimeInterval(-right)
//}
//
//public func -= (left: inout Date, right: TimeInterval) {
//    left = left.addingTimeInterval(-right)
//}
//
//public func + (left: Date, right: TimeInterval) -> Date {
//    return left.addingTimeInterval(right)
//}
//
//public func += (left: inout Date, right: TimeInterval) {
//    left = left.addingTimeInterval(right)
//}
//
//public func - (left: Date, right: CalendarType) -> Date {
//    let calendarType = right.copy()
//    calendarType.amount = -calendarType.amount
//    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
//    let dateComponents = calendarType.dateComponents()
//    let finalDate = (calendar as NSCalendar).date(byAdding: dateComponents, to: left, options: [])!
//    return finalDate
//}
//
//public func -= (left: inout Date, right: CalendarType) {
//    left = left - right
//}
//
//public func + (left: Date, right: CalendarType) -> Date {
//    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
//    return (calendar as NSCalendar).date(byAdding: right.dateComponents(), to: left, options: [])!
//}
//
//public func += (left: inout Date, right: CalendarType) {
//    left = left + right
//}
//
//public func - (left: Date, right: Date) -> TimeInterval {
//    return left.timeIntervalSince(right)
//}
//
////MARK: SUPPORTING STRUCTURES
//
//open class CalendarType {
//    var calendarUnit : NSCalendar.Unit
//    var amount : Int
//    
//    init(amount : Int) {
//        self.calendarUnit = []
//        self.amount = amount
//    }
//    
//    init(amount: Int, calendarUnit: NSCalendar.Unit) {
//        self.calendarUnit = calendarUnit
//        self.amount = amount
//    }
//    
//    func dateComponents() -> DateComponents {
//        return DateComponents()
//    }
//    
//    func copy() -> CalendarType {
//        return CalendarType(amount: self.amount, calendarUnit: self.calendarUnit)
//    }
//}
//
//open class MonthCalendarType : CalendarType {
//    
//    override init(amount : Int) {
//        super.init(amount: amount)
//        self.calendarUnit = NSCalendar.Unit.month
//    }
//    
//    override func dateComponents() -> DateComponents {
//        var components = super.dateComponents()
//        components.month = self.amount
//        return components
//    }
//    
//    override func copy() -> MonthCalendarType {
//        let objCopy =  MonthCalendarType(amount: self.amount)
//        objCopy.calendarUnit = self.calendarUnit
//        return objCopy;
//    }
//}
//
//open class YearCalendarType : CalendarType {
//    
//    override init(amount : Int) {
//        super.init(amount: amount, calendarUnit: NSCalendar.Unit.year)
//    }
//    
//    override func dateComponents() -> DateComponents {
//        var components = super.dateComponents()
//        components.year = self.amount
//        return components
//    }
//    
//    override func copy() -> YearCalendarType {
//        let objCopy =  YearCalendarType(amount: self.amount)
//        objCopy.calendarUnit = self.calendarUnit
//        return objCopy
//    }
//}
//
//public extension Int {
//    var seconds : TimeInterval {
//        return TimeInterval(self)
//    }
//    var second : TimeInterval {
//        return (self.seconds)
//    }
//    var minutes : TimeInterval {
//        return (self.seconds*60)
//    }
//    var minute : TimeInterval {
//        return self.minutes
//    }
//    var hours : TimeInterval {
//        return (self.minutes*60)
//    }
//    var hour : TimeInterval {
//        return self.hours
//    }
//    var days : TimeInterval {
//        return (self.hours*24)
//    }
//    var day : TimeInterval {
//        return self.days
//    }
//    var weeks : TimeInterval {
//        return (self.days*7)
//    }
//    var week : TimeInterval {
//        return self.weeks
//    }
//    var workWeeks : TimeInterval {
//        return (self.days*5)
//    }
//    var workWeek : TimeInterval {
//        return self.workWeeks
//    }
//    var months : MonthCalendarType {
//        return MonthCalendarType(amount: self)
//    }
//    var month : MonthCalendarType {
//        return self.months
//    }
//    var years : YearCalendarType {
//        return YearCalendarType(amount: self)
//    }
//    var year : YearCalendarType {
//        return self.years
//    }
//}
//
////MARK: PRIVATE STRING EXTENSION
//
//private extension String {
//    
//    var _sdLocalize: String {
//        return Bundle.main.localizedString(forKey: self, value: nil, table: "SwiftDates")
//    }
//    
//    func _sdToCalendarUnit() -> NSCalendar.Unit {
//        switch self {
//        case "year":
//            return NSCalendar.Unit.year
//        case "month":
//            return NSCalendar.Unit.month
//        case "weekOfYear":
//            return NSCalendar.Unit.weekOfYear
//        case "day":
//            return NSCalendar.Unit.day
//        case "hour":
//            return NSCalendar.Unit.hour
//        case "minute":
//            return NSCalendar.Unit.minute
//        case "second":
//            return NSCalendar.Unit.second
//        default:
//            return []
//        }
//    }
//}
//
//public enum DateFormat {
//    case iso8601, rss, altRSS
//    case custom(String)
//}
//
//let D_SECOND = 1
//let D_MINUTE = 60
//let D_HOUR = 3600
//let D_DAY = 86400
//let D_WEEK = 604800
//let D_YEAR = 31556926
