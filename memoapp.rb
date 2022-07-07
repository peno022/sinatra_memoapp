# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'json'
require 'pg'

enable :sessions

ERROR_MESSAGE_EMPTY_MEMO = 'タイトル、内容にはテキストを入力してください。'

DB = {
  db_name: 'sinatra_memoapp',
  host: ENV['DB_HOST'],
  user: ENV['DB_USER'],
  port: ENV['DB_PORT']
}.freeze
class Memo
  attr_accessor :title, :content
  attr_reader :id, :created_at, :updated_at

  def initialize(id, title, content, created_at, updated_at)
    @id = id
    @title = title
    @content = content
    @created_at = created_at
    @updated_at = updated_at
  end

  def self.all
    db_exec_select_all.map do |memo|
      Memo.new(*memo.slice('id', 'title', 'content', 'created_at', 'updated_at').values)
    end
  end

  def self.find_by_id(id)
    memo = db_exec_select_by_id(id).first
    return if memo.empty?

    Memo.new(*memo.slice('id', 'title', 'content', 'created_at', 'updated_at').values)
  end

  def create
    db_exec_create(title, content)
  end

  def delete
    db_exec_delete(id)
  end

  def update
    db_exec_update(title, content, id)
  end
end

get '/' do
  redirect '/memos'
  erb :index
end

get '/memos' do
  @memos = Memo.all
  erb :index
end

get '/memos/new' do
  erb :new
end

get '/memos/edit/:id' do
  @memo = Memo.find_by_id(params['id'])
  if @memo
    erb :edit
  else
    status 404
  end
end

get '/memos/:id' do
  @memo = Memo.find_by_id(params['id'])
  if @memo
    erb :detail
  else
    status 404
  end
end

post '/memos' do
  if params['title'].strip.empty? || params['content'].strip.empty?
    show_error_message(ERROR_MESSAGE_EMPTY_MEMO)
    redirect '/memos/new'
    return
  end

  memo = Memo.new(nil, params['title'], params['content'], nil, nil)
  memo.create
  redirect '/memos'
  erb :index
end

patch '/memos/:id' do
  target_memo = Memo.find_by_id(params['id'])
  unless target_memo
    status 404
    return
  end

  if params['title'].strip.empty? || params['content'].strip.empty?
    show_error_message(ERROR_MESSAGE_EMPTY_MEMO)
    redirect "/memos/#{params['id']}"
    return
  end

  target_memo.title = params['title']
  target_memo.content = params['content']
  target_memo.update
  redirect '/memos'
  erb :index
end

delete '/memos/:id' do
  target_memo = Memo.find_by_id(params['id'])
  unless target_memo
    status 404
    return
  end

  target_memo.delete
  redirect '/memos'
  erb :index
end

not_found do
  send_file 'public/404.html'
end

error do
  send_file 'public/500.html'
end

def show_error_message(message)
  flash[:error] = message
end

def db_exec_select_all
  conn = db_connect
  conn.exec('SELECT * FROM memos')
end

def db_exec_create(title, content)
  conn = db_connect
  conn.prepare('create', 'INSERT INTO memos(title, content) VALUES ($1, $2)')
  conn.exec_prepared('create', [title, content])
end

def db_exec_select_by_id(id)
  conn = db_connect
  conn.prepare('select_by_id', 'SELECT * FROM memos WHERE id = ($1)')
  conn.exec_prepared('select_by_id', [id])
end

def db_exec_update(title, content, id)
  conn = db_connect
  conn.prepare('update', 'UPDATE memos SET title=($1), content=($2), updated_at=CURRENT_TIMESTAMP where id = ($3)')
  conn.exec_prepared('update', [title, content, id])
end

def db_exec_delete(id)
  conn = db_connect
  conn.prepare('delete', 'DELETE FROM memos WHERE id = ($1)')
  conn.exec_prepared('delete', [id])
end

def db_connect
  PG.connect(host: DB[:host], port: DB[:port], dbname: DB[:db_name], user: DB[:user])
end
