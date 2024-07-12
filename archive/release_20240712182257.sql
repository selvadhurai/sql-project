-- Connect to the 'geneart' database
\c geneart;

-- Create a sample table
CREATE TABLE sample_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- Insert some sample data into the table
INSERT INTO sample_table (name, age, email)
VALUES
('John Doe', 30, 'john.doe@example.com'),
('Jane Smith', 25, 'jane.smith@example.com'),
('Alice Johnson', 28, 'alice.johnson@example.com'),
('Bob Brown', 35, 'bob.brown@example.com');