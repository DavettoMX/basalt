# Basalt: Ruby Detection & Extraction

## Detection Patterns

### Database / Schema
- `**/db/schema.rb` — ActiveRecord schema definition
- `**/db/migrate/**/*.rb` — ActiveRecord migrations
- `**/app/models/**/*.rb` containing `< ApplicationRecord` or `< ActiveRecord::Base` — ActiveRecord models

### API / Routes
- `**/config/routes.rb` containing `resources`, `get`, `post`, `namespace` — Rails routes
- `**/app/controllers/**/*.rb` containing `< ApplicationController` — Rails controllers
- `**/*.rb` containing `Sinatra::Base` or `get '/'` — Sinatra

### Application / Business Logic
- `**/app/services/**/*.rb` — Service objects
- `**/app/jobs/**/*.rb` containing `< ApplicationJob` or `< ActiveJob::Base` — Background jobs
- `**/lib/**/*.rb` — Library modules

## Extraction Rules

### Database spec.decree
- `t.string` → `s`, `t.integer` → `i`, `t.float`/`t.decimal` → `f`, `t.boolean` → `b`, `t.datetime` → `t`, `t.jsonb`/`t.json` → `j`
- `null: false` → required. `null: true` (default) → `?` prefix
- `index: { unique: true }` or `add_index ..., unique: true` → `@unique`
- `add_index :table, [:col1, :col2]` → `#[col1,col2]`
- `t.references :entity` or `belongs_to :entity` → `->Entity.id`
- `default: value` → `=val`

### API spec.decree
- `resources :users` → standard CRUD routes for users
- `get '/path'` → `GET /path`, `post '/path'` → `POST /path`
- `before_action :authenticate!` → `@auth`
- Strong parameters (`params.require(:entity).permit(...)`) → `>fields`

### Application spec.decree
- Service classes (plain Ruby classes in `services/`) → `+ClassName` with `.call(params) ->return` or public methods
- Job classes → `+JobName` with `.perform(params)`
- Module constants → `K NAME type =value`

### body.decree additions
- **Database:** ActiveRecord callbacks (`before_save`, `after_create`), scopes, enum declarations (`enum status: {}`), STI patterns
- **API:** Devise/Warden auth, Pundit/CanCanCan authorization, Sidekiq background job integration, Action Cable websockets
- **Application:** service object patterns (`.call` convention), concerns/mixins, ActiveSupport extensions
