require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database

  include Singleton

  def initialize
    super("questions.db")

    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
  # raise "User already exists!" unless self.id.nil?
  attr_reader :id
  attr_accessor :fname, :lname


  def self.find_by_id(id)
   options = QuestionsDatabase.instance.execute(<<-SQL, id)
     SELECT
       *
     FROM
       users
     WHERE
       id = ?
   SQL

   User.new(options[0])
  end

  def self.find_by_name(fname, lname)
    options = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL

    User.new(options[0])
  end

  def self.get_author_name(id)
    options = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL

    author = User.new(options[0])

    "#{author.fname} #{author.lname}"
  end

  def initialize(options = {})
    @id = options["id"]
    @fname = options["fname"]
    @lname = options["lname"]
  end

  def save
    if @id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
      SQL
    end

    nil
  end

  def authored_questions
    Question.find_by_user_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    QuestionsDatabase.instance.execute(<<-SQL, @id)
        SELECT
        /* doesn't round up! */
          ROUND(num_likes / my_qid)
        FROM (
          SELECT
            COUNT(liked) num_likes, my_q.id my_qid
          FROM
            question_likes ql INNER JOIN (
              SELECT
                *
              FROM
                questions
              WHERE
                user_id = ?) my_q
            ON ql.question_id = my_q.id
          WHERE ql.liked = 'true') x
    SQL
  end

end

class Question

  attr_reader :id, :user_id
  attr_accessor :title, :body

  def self.most_followed(n)
    QuestionFollower::most_followed_questions(n)
  end

  def self.find_by_user_id(user_id)
    options = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions
      WHERE
        user_id = ?
    SQL

    options.map { |option| Question.new(option) }
  end

  def self.find_by_id(id)
   options = QuestionsDatabase.instance.execute(<<-SQL, id)
     SELECT
       *
     FROM
       questions
     WHERE
       id = ?
   SQL

   Question.new(options[0])
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def initialize(options = {})
    @id = options["id"]
    @title = options["title"]
    @body = options["body"]
    @user_id = options["user_id"]
  end

  def save
    if @id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id)
      INSERT INTO
        questions (title, body, user_id)
      VALUES
        (?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id, @id)
      UPDATE
        questions
      SET
        title = ?, body = ?, user_id = ?
      WHERE
        id = ?
      SQL
    end

    nil
  end

  def author
    User.get_author_name(@user_id)
  end

  def replies
    Reply.get_replies_by_question(@id)
  end

  def question_followers
    QuestionFollower.followers_for_question_id(@id)
  end

  def likers
    QuestionLike::likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike::num_liked_for_question_id(@id)
  end
end

class QuestionFollower

  attr_reader :id, :question_id, :user_id

  def self.most_followed_questions(n)
    follower_count = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        COUNT(id)
      FROM
        question_followers
      GROUP BY
        question_id
      ORDER BY
        COUNT(id) DESC
      LIMIT
        ?
    SQL

    follower_count
  end

  def self.find_by_id(id)
   options = QuestionsDatabase.instance.execute(<<-SQL, id)
     SELECT
       *
     FROM
       question_followers
     WHERE
       id = ?
   SQL

   QuestionFollower.new(options[0])
  end

  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        u.id
      FROM
        question_followers q JOIN users u
        ON q.user_id = u.id
      WHERE
        question_id = ?
    SQL

    followers_str = ""

    follower_ids = []
    followers.each do |follower|
      follower_ids << follower["id"]
    end

    follower_ids.each do |id|
      followers_str += "#{User.get_author_name(id)}\n\n"
    end

    followers_str
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        q.title, q.body
      FROM
        question_followers qf INNER JOIN questions q
        ON qf.question_id = q.id
      WHERE
        qf.user_id = ?
      GROUP BY
        q.user_id
    SQL

    questions
    # returns an array of hashes including question title and body for particular user!
  end

  def initialize(options = {})
    @id = options["id"]
    @question_id = options["question_id"]
    @user_id = options["user_id"]
  end

end

class Reply

  attr_reader :id, :question_id, :user_id, :parent_id
  attr_accessor :body

  def self.find_by_user_id(user_id)
    options = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL

    options.map { |option| Reply.new(option) }
  end

  def self.find_by_id(id)
   options = QuestionsDatabase.instance.execute(<<-SQL, id)
     SELECT
       *
     FROM
       replies
     WHERE
       id = ?
   SQL

   Reply.new(options[0])
  end

  def self.get_replies_by_question(question_id)
    options = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    replies = options.map { |option| Reply.new(option) }

    all_replies_str = ""

    replies.each do |reply|
      all_replies_str += "#{reply.body}\n\n"
    end

    all_replies_str
  end

  def initialize(options = {})
    @id = options["id"]
    @question_id = options["question_id"]
    @user_id = options["user_id"]
    @parent_id = options["parent_id"]
    @body = options["body"]
  end

  def save
    if @id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, @question_id, @user_id, @parent_id, @body)
      INSERT INTO
        replies (question_id, user_id, parent_id, body)
      VALUES
        (?, ?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, @question_id, @user_id, @parent_id, @body, @id)
      UPDATE
        replies
      SET
        question_id = ?, user_id = ?, parent_id = ?, body = ?
      WHERE
        id = ?
      SQL
    end

    nil
  end

  def author
    User.get_author_name(@user_id)
  end

  def parent_reply
    raise "Original reply; has no parent." if @parent_id.nil?
    Reply.find_by_id(@parent_id)
  end

  def parent_author
    parent = parent_reply
    parent.author
  end

  def child_replies
    options = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL

    child_replies = options.map { |option| Reply.new(option) }
  end

end

class QuestionLike

  attr_reader :id, :question_id, :user_id, :liked

  def self.find_by_id(id)
   options = QuestionsDatabase.instance.execute(<<-SQL, id)
     SELECT
       *
     FROM
       question_likes
     WHERE
       id = ?
   SQL

   QuestionLike.new(options[0])
  end

  def self.num_liked_for_question_id(question_id)
    num_liked = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(liked) num_liked
      FROM
        question_likes ql
      WHERE
        ql.question_id = ? AND ql.liked = 'true'
    SQL

    num_liked
  end

  def self.likers_for_question_id(question_id)
    liker_name = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        u.fname, u.lname
      FROM
        question_likes ql INNER JOIN users u ON ql.user_id = u.id
      WHERE
        ql.question_id = ? AND ql.liked = 'true'
    SQL

    liker_name
  end

  def self.liked_questions_for_user_id(user_id)
    liked_questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        q.title, q.body
      FROM
        question_likes ql INNER JOIN questions q ON ql.question_id = q.id
      WHERE
        ql.user_id = ? AND ql.liked = 'true'
    SQL

    liked_questions
  end

  def self.most_liked_questions(n)
    liked_count = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        q.title, q.body
      FROM questions q INNER JOIN (
        SELECT
          question_id, COUNT(id)
        FROM
          question_likes
        WHERE
          liked = 'true'
        GROUP BY
          question_id
        ORDER BY
          COUNT(id) DESC
        LIMIT
          ?) num_likes
      ON num_likes.question_id = q.id

    SQL

    liked_count
  end

  def initialize(options = {})
    @id = options["id"]
    @question_id = options["question_id"]
    @user_id = options["user_id"]
    @liked = options["liked"]
  end

end

class Tags

  def self.most_popular(n)
    # returns the n most popular (tot # of likes for all questions for a given tag) tags.
  end

  def initialize

  end

  def most_popular_questions(n)
    # returns the n most popular (# of likes) questions for tag.
  end

end