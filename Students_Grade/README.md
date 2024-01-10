Here is the explanation of the MySQL code in SQL_case_students_grade.sql

I used the data from SchoolSchedulingExample schema, and here is the EER Diagram of this schema:
![mySQL](https://github.com/HuLilyowo/SQL_Projects/assets/133606096/673adc40-3500-4140-b8bc-1f9ce1f03756)

This project aims to get the current overall weighted grade and letter grade for each student. Notice this goal, only the following tables are relevant to our purpose:
  - Student_Schedules
  - Classes
  - Students
  - Majors
  - ztbLetterGrades


### Step 1. 
Students only have the scores from completed courses. We need to get the fundamental information of students' profiles (Student ID, Name, and Major) and filter all the completed courses (class status: 1-enrolled, 2-completed, 3-withdraw)

```SQL
CREATE TEMPORARY TABLE grade_book AS
SELECT ss.StudentID AS Student_ID,
CONCAT(StudFirstName," ", StudLastName) AS Student_Full_Name,
Major,ss.ClassID AS Class_ID,Credits,Grade
FROM Student_Schedules ss 
LEFT JOIN Classes c ON ss.ClassID = c.ClassID
LEFT JOIN Students s ON s.StudentID = ss.StudentID
LEFT JOIN Majors m ON s.StudMajor = m.MajorID
WHERE ClassStatus = 2;
```
I created a temporary table because I'll need to run a function based on this later, and it'll be clearer to code this part separately. 

The grade_book temporary table looks like this (only shows the first 10 rows):

![image](https://github.com/HuLilyowo/SQL_Projects/assets/133606096/676a054e-9062-4d32-a6aa-999030eee0ba)

### Step 2.
We can see that the grade_book table shows every completed course of a student with the representative score. We want the overall scores for each one and give them the letter score according to the following range from table ztbLetterGrades: 

![image](https://github.com/HuLilyowo/SQL_Projects/assets/133606096/cc69d747-6ed8-47a9-ad8d-119294a5b7ef)

We need a function to compare the score and the range of each letter grade.

```SQL
# reset delimiter
DELIMITER //

# to solve error code 1418 
SET GLOBAL log_bin_trust_function_creators = 1;

# create the function that takes a numeric score
# compares it to the given ranges of letter scores
# and returns the representative letter score
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

# change delimiter back to ";"
DELIMITER ;
```

### Step 3
Using grade_book and return_letter_grade function to get the overall scores for students.

```SQL
SELECT Student_ID, Student_Full_Name, Major, Avg_Grade_Weighted,
# use the avg_grade_weighted to run the function
# (below shows the calculation)
return_letter_grade(avg_grade_weighted) AS Overall_Letter_Grade
FROM
(SELECT Student_ID, Student_Full_Name, Major,
# calculate the weighted average score
ROUND(SUM(Credits*Grade)/SUM(Credits),2) AS Avg_Grade_Weighted
FROM grade_book
GROUP BY Student_ID, Student_Full_Name, Major) AS sub_table;
```
And here is the result:

![image](https://github.com/HuLilyowo/SQL_Projects/assets/133606096/f1afa845-43b6-47f2-b73d-2c5bb75eec59)


