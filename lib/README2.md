-- Create the database
CREATE DATABASE user_management;
\c user_management;  -- Connect to the database

-- Create the Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,                         
    email VARCHAR(255) NOT NULL UNIQUE,           
    firstname VARCHAR(100),                        
    lastname VARCHAR(100),                         
    image_address VARCHAR(255),                    
    password VARCHAR(255) NOT NULL,                
    has_plan BOOLEAN NOT NULL DEFAULT FALSE,       
    expire_at TIMESTAMPTZ                         
);

-- Create the User Strings table
CREATE TABLE user_strings (
    id SERIAL PRIMARY KEY,                         
    user_id INT NOT NULL,                          
    string_value VARCHAR(255) NOT NULL,            
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create the User Purchase History table
CREATE TABLE user_purchase_history (
    id SERIAL PRIMARY KEY,                         
    user_id INT NOT NULL,                          
    purchase_date TIMESTAMPTZ NOT NULL,           
    amount DECIMAL(10, 2) NOT NULL,               
    description VARCHAR(255),                       
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create the User Request History table
CREATE TABLE user_request_history (
    id SERIAL PRIMARY KEY,                         
    user_id INT NOT NULL,                          
    request_date TIMESTAMPTZ NOT NULL,            
    request_type VARCHAR(100) NOT NULL,            
    status VARCHAR(50),                            
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);