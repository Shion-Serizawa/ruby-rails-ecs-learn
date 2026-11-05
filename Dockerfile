# syntax=docker/dockerfile:1
# check=error=true

# 本番用イメージ (ECS 想定)。開発用は Dockerfile.dev / compose.yaml を参照。
#   docker build -t conf_notes .
#   ローカル確認: docker compose -f compose.production.yaml up --build
#
# 同じイメージを command 違いで使い分ける:
#   web    : (デフォルト) ./bin/thrust ./bin/rails server   … Thruster が :80 で待ち受け
#   worker : ./bin/jobs                                      … Solid Queue
#   migrate: ./bin/rails db:prepare                          … デプロイ前の単発タスク

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=4.0.9
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 postgresql-client && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# RDS の CA バンドル。DB 接続を sslmode=verify-full で検証するために使う (config/database.yml)
RUN curl -fsSL --proto =https -o /etc/ssl/certs/rds-global-bundle.pem \
      https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

# Set production environment variables and enable jemalloc for reduced memory usage and latency.
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY vendor/* ./vendor/
COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    # -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
    bundle exec bootsnap precompile -j 1 --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times.
# -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
RUN bundle exec bootsnap precompile -j 1 app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile




# Final stage for app image
FROM base

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

# Copy built artifacts: gems, application
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
# 非 root ユーザーは 1024 未満のポートを bind できない環境がある (Fargate 等) ため 8080 で待ち受ける。
# ローカルの Docker で :80 が動くのは Docker が ip_unprivileged_port_start=0 を設定しているから
ENV HTTP_PORT="8080"
EXPOSE 8080
CMD ["./bin/thrust", "./bin/rails", "server"]
