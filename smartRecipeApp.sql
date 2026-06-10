create database cookit_now;
use cookit_now;

CREATE TABLE userdetails (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NULL,
    provider ENUM('Google', 'Email', 'Facebook') DEFAULT 'Email',
    contact_number VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_health_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    age INT NULL,
    gender ENUM('Male', 'Female', 'Other') NULL,
    height_cm FLOAT NULL,
    weight_kg FLOAT NULL,
    bmr FLOAT NULL,
    diabetes BOOLEAN NOT NULL DEFAULT FALSE,
    high_blood_pressure BOOLEAN NOT NULL DEFAULT FALSE,
    cholesterol BOOLEAN NOT NULL DEFAULT FALSE,
    kidney_issues BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_user_health_details_user
        FOREIGN KEY (user_id) REFERENCES userdetails(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE recipes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    recipe_title VARCHAR(255),
    url TEXT,
    record_health VARCHAR(50),
    vote_count INT,
    rating FLOAT,
    description TEXT,
    cuisine VARCHAR(150),
    course VARCHAR(150),
    diet VARCHAR(150),
    prep_time VARCHAR(50),
    cook_time VARCHAR(50),
    ingredients TEXT,
    instructions TEXT,
    author VARCHAR(255),
    tags TEXT,
    category VARCHAR(255)
);


CREATE TABLE saved_recipes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_email VARCHAR(150) NOT NULL,
    recipe_id INT NOT NULL,
    saved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY unique_user_recipe (user_email, recipe_id),

    CONSTRAINT fk_saved_recipes_user_email
        FOREIGN KEY (user_email) REFERENCES userdetails(email)
        ON DELETE CASCADE,

    CONSTRAINT fk_saved_recipes_recipe_id
        FOREIGN KEY (recipe_id) REFERENCES recipes(id)
        ON DELETE CASCADE
);

CREATE TABLE chat_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_email VARCHAR(150) NOT NULL,
    title VARCHAR(255) DEFAULT 'New Chat',
    messages_json LONGTEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_chat_sessions_user_email
        FOREIGN KEY (user_email) REFERENCES userdetails(email)
        ON DELETE CASCADE
);
ALTER TABLE userdetails
DROP COLUMN age,
DROP COLUMN gender,
DROP COLUMN height_cm,
DROP COLUMN weight_kg,
DROP COLUMN bmr,
DROP COLUMN diabetes,
DROP COLUMN high_blood_pressure,
DROP COLUMN cholesterol,
DROP COLUMN kidney_issues;



select*from userdetails;
select*from user_health_details;
select*from recipes;
select*from saved_recipes;
select*from chat_sessions;
delete from userdetails where id=5; 

ALTER TABLE recipes 
MODIFY description TEXT,
MODIFY instructions TEXT;

DESCRIBE recipes;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE saved_recipes;
TRUNCATE TABLE recipes;

SET FOREIGN_KEY_CHECKS = 1;


SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 0;
