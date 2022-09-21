#!/bin/bash

re=^[A-Za-z0-9_-]+$

project=""
while ! [[ "${project?}" =~ ${re} ]]
do
  read -p "🔷 Enter the project name (can use letters, numbers, dash or underscore): " project
done

repository=""
currentRepo="https://github.com/edwardramirez31/micro-frontend-root-layout"
read -p "🔷 Enter your GitHub repository URL name to add semantic release: " repository
sed -i "s,$currentRepo,$repository,g" .releaserc

while true; do
    read -p "🔷 Do you want to deploy this root module to AWS S3? [y/N]: " yn
    case $yn in
        [Yy]* )
          bucketValidation=^[a-z0-9.-]+$
          bucketName=""
          while ! [[ "${bucketName?}" =~ ${bucketValidation} ]]
          do
            read -p "🔷 Enter your S3 Bucket Name: " bucketName
          done
          sed -i "s/mf-todo/$bucketName/g" .github/workflows/main.yml
          sed -i "s/mf-todo/$bucketName/g" src/index.ejs
          echo "⚠️  Don't forget to setup bucket access and ACL so that the root module can get your build file"
          break
        ;;
        [Nn]* )
          sed -i.bak -e '49,58d' .github/workflows/main.yml && rm .github/workflows/main.yml.bak
          break
        ;;
        * ) echo "Please answer yes or no like: [y/N]";;
    esac
done

sed -i "s/my-app/$project/g" package.json
sed -i "s/my-app/$project/g" tsconfig.json
sed -i "s/'my-app'/'$project'/g" webpack.config.js
sed -i "s/my-app/$project/g" src/index.ejs
mv src/my-app-root-config.ts "src/$project-root-config.ts"


echo "🔥🔨 Installing dependencies"
# yarn install
echo "🔥⚙️ Installing Git Hooks"
# yarn husky install
echo "🚀🚀 Project setup complete!"
echo "✔️💡 Run 'yarn start' to boot up your single-spa root config"
