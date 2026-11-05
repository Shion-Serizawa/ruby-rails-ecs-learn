Rails.application.routes.draw do
  # 認証 (bin/rails generate authentication + 新規登録)
  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  resources :passwords, param: :token, only: %i[new create edit update]

  # 構造化データ(JSON)からの一括インポート。schema は LLM に渡す JSON Schema
  resource :conference_import, only: %i[new create] do
    get :schema
  end

  resources :conferences do
    resource :export, only: :create, module: :conferences
    resources :talks, except: :index, shallow: true do
      resource :favorite, only: :update, module: :talks
    end
  end

  # 開発環境ではメールをブラウザで確認できる
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # ロードバランサ(ALB)のヘルスチェック用。アプリが起動していれば 200 を返す
  get "up" => "rails/health#show", as: :rails_health_check

  root "conferences#index"
end
