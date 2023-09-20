# openstreetmap

github代理配置 :`git config --global url."https://ghproxy.com/https://github.com".insteadOf "https://github.com"`

取消代理 : `git config --global --unset http.https://github.com.proxy`

## docker

ubuntu需要的构建环境，参考[INSTALL steps](INSTALL.md)

- ruby
- gem
- bundle
- nodejs
- npm

### Initial Setup

    cp config/example.storage.yml config/storage.yml
    cp config/docker.database.yml config/database.yml
    touch config/settings.local.yml

### Installation

    docker-compose build
    docker-compose up -d

### Migrations （需要时）

    docker-compose run --rm web bundle exec rails db:migrate

## 注意

    edit页面需要执行： rake i18n:js:export 和 rails assets:precompile

### 注册成功或者找回密码时候，表单提交后，控制台会打印邮件内容，点击链接即可

```html
 <h1>注册验证链接：</h1>
<p style="color: black; margin: 0.75em 0; font-family: 'Helvetica Neue', Arial, sans-serif">
  <a
    href="http://localhost:3000/user/zhaoyuehai5282/confirm?confirm_string=kDyMhbLOKvm3jzUQeYD19Z6ePz9PYH">
    http://localhost:3000/user/zhaoyuehai5282/confirm?confirm_string=kDyMhbLOKvm3jzUQeYD19Z6ePz9PYH
  </a>
</p>
<h1>找回密码验证链接：</h1>
<p style="color: black; margin: 0.75em 0; font-family: 'Helvetica Neue', Arial, sans-serif">
  <a href="http://localhost:3000/user/reset-password?token=wAyq4Pgi7CiyXA407cc5JkJlCRugof">
    http://localhost:3000/user/reset-password?token=wAyq4Pgi7CiyXA407cc5JkJlCRugof
  </a>
</p>
```

### 编辑地图

需要添加OAuth Consumer Keys，参考[configuration steps](CONFIGURE.md)


