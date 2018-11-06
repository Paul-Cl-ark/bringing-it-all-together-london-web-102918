require 'pry'

class Dog

  attr_accessor :name, :breed
  attr_reader :id

  @@dogs = Array.new

  def initialize(id=nil, dog_hash)
    @id = id
    @name = dog_hash[:name]
    @breed = dog_hash[:breed]
  end

  def self.all
    @@dogs
  end

  def self.create_table
    sql = <<-SQL
      CREATE TABLE
      IF NOT EXISTS dogs
      (id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT);
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
      DROP TABLE
      IF EXISTS dogs;
    SQL

    DB[:conn].execute(sql)
  end

  def save
    sql = <<-SQL
      INSERT INTO dogs
      (name, breed)
      VALUES (?, ?);
    SQL

    DB[:conn].execute(sql, self.name, self.breed)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs").first.first
    self
  end

  def self.create(dog_hash)
    dog = Dog.new(dog_hash)
    dog.save
    dog
  end

  def self.new_from_db(row)
    new_dog = self.new(row[0], dog_hash = {name: row[1], breed: row[2]})
    new_dog
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE id = ?
      LIMIT 1;
    SQL

  DB[:conn].execute(sql, id).map {|row| self.new_from_db(row)}.first
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ?
      LIMIT 1;
    SQL

    DB[:conn].execute(sql, name).map {|row| self.new_from_db(row)}.first
  end

  def self.find_or_create_by(name:, breed:)
    dog_row = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?;", name, breed)
    if !dog_row.empty?
      dog_info = dog_row[0]
      dog = Dog.new(dog_info[0], dog_hash = {name: dog_row[1], breed: dog_row[2]})
    else
      dog = self.create(name: name, breed: breed)
    end
    dog
  end

  def update
    sql = <<-SQL
      UPDATE dogs
      SET name = ?, breed = ?
      WHERE id = ?
    SQL

    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end

end
