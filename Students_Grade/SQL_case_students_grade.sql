# Grade Report to Students
# Get the records on completed classes for each student
# class status: 1-enrolled, 2-completed, 3-withdraw (we can only get score for status 2)

CREATE TEMPORARY TABLE grade_book AS
SELECT ss.StudentID AS Student_ID,
CONCAT(StudFirstName," ", StudLastName) AS Student_Full_Name,
Major,ss.ClassID AS Class_ID,Credits,Grade
FROM Student_Schedules ss 
LEFT JOIN Classes c ON ss.ClassID = c.ClassID
LEFT JOIN Students s ON s.StudentID = ss.StudentID
LEFT JOIN Majors m ON s.StudMajor = m.MajorID
WHERE ClassStatus = 2;

# Calculate weighted average grade & overall letter grade by class credits

# Create function for getting letter grade
DELIMITER //

SET GLOBAL log_bin_trust_function_creators = 1;

CREATE FUNCTION return_letter_grade(score FLOAT) RETURNS VARCHAR(5)
BEGIN
    DECLARE letter_grade VARCHAR(5);
    SELECT LetterGrade INTO letter_grade
    FROM ztblLetterGrades
    WHERE score BETWEEN LowGradePoint AND HighGradePoint
    ORDER BY HighGradePoint DESC
    LIMIT 1;
    RETURN letter_grade;
END //

DELIMITER ;

SELECT Student_ID, Student_Full_Name, Major, Avg_Grade_Weighted, 
return_letter_grade(avg_grade_weighted) AS Overall_Letter_Grade
FROM
(SELECT Student_ID, Student_Full_Name, Major,
ROUND(SUM(Credits*Grade)/SUM(Credits),2) AS Avg_Grade_Weighted
FROM grade_book
GROUP BY Student_ID, Student_Full_Name, Major) AS sub_table;

# drop the function and temporary table since I don't need them so far
DROP TEMPORARY TABLE grade_book;
DROP FUNCTION return_letter_grade;
