-- Spider: employee_hire_evaluation (adapted)
-- Tests: self-referencing FK, nullable self-ref, cross-entity FK

CREATE TABLE Employee (
    employee_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    hire_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    salary FLOAT NOT NULL,
    manager_id INTEGER REFERENCES Employee(employee_id)
);

CREATE INDEX idx_employee_manager ON Employee(manager_id);
CREATE INDEX idx_employee_hire ON Employee(hire_date);

CREATE TABLE Department (
    department_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    budget FLOAT NOT NULL DEFAULT 0,
    head_id INTEGER NOT NULL REFERENCES Employee(employee_id)
);

CREATE INDEX idx_department_head ON Department(head_id);

CREATE TABLE Evaluation (
    evaluation_id INTEGER PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES Employee(employee_id),
    evaluator_id INTEGER NOT NULL REFERENCES Employee(employee_id),
    score FLOAT NOT NULL,
    comments TEXT,
    evaluated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_eval_employee ON Evaluation(employee_id);
CREATE INDEX idx_eval_evaluator ON Evaluation(evaluator_id);
CREATE INDEX idx_eval_date ON Evaluation(evaluated_at);
