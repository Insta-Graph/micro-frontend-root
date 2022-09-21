# React Micro Frontend Template

## Getting Started

1. Run the script to initialize the project and install dependencies:

```bash
./setup.sh
```

2. Add your micro frontend apps at `src/index.ejs`

```html
<script type="systemjs-importmap">
  {
    "imports": {
      "react": "https://cdn.jsdelivr.net/npm/react@16.13.0/umd/react.production.min.js",
      "react-dom": "https://cdn.jsdelivr.net/npm/react-dom@16.13.0/umd/react-dom.production.min.js",
      "single-spa": "https://cdn.jsdelivr.net/npm/single-spa@5.3.0/lib/system/single-spa.min.js",
      "@${PROJECT_NAME}/root-config": "//localhost:9000/${PROJECT_NAME}-root-config.js",
      "@${PROJECT_NAME}/{MICRO_FRONTEND_NAME}": "//localhost:${YOUR_PORT}/${PROJECT_NAME}-{MICRO_FRONTEND_NAME}.js"
    }
  }
</script>
```

3. Register your micro frontend apps at `microfrontend-layout.html`. You can read more about the layout API reference [here](https://single-spa.js.org/docs/layout-definition/)

```html
<single-spa-router>
  <main>
    <route default>
      <application name="@single-spa/welcome"></application>
    </route>
    <!-- Registering new micro frontend here (EXAMPLE) -->
    <route path="${YOUR_PATH}">
      <application name="@${PROJECT_NAME}/${MICRO_FRONTEND_NAME}"></application>
    </route>
  </main>
</single-spa-router>
```

4. Execute `yarn start` to run locally

## Important notes

- Maintain consistency for the project name (all micro service and root project should have the same project name)

- It's recommended to setup the micro frontend apps repositories from [this template](https://github.com/edwardramirez31/micro-frontend-template) to be consistent with project naming convention

- This repository uses Semantic Release. If you don't want to use it:

  - Remove the step at `.github` or the entire folder
  - Remove `.releaserc` file
  - Remove `@semantic-release/changelog`, `@semantic-release/git`, `semantic-release` from `package.json`

- Build the project with `yarn build` and deploy the files to a CDN or host to serve those static files.

- This project uses AWS S3 to host the build files and the root HTML. In order to use this feature properly:

  - Create an IAM user with S3 permissions and setup `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` at repository secrets
  - Type your bucket name when executing `setup.sh`
  - Create an S3 bucket at AWS and change bucket settings according to your needs

    - Enable S3 Static Website Hosting at the bottom of the Properties tab in the AWS Management Console
      - Set the index document as `index.html`
    - Uncheck all options at bucket settings or just whatever is necessary
    - Change bucket policy allowing externals to get your objects if you want to serve content directly from the bucket

    ```
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": "*",
          "Action": "s3:GetObject",
          "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
        }
      ]
    }
    ```

    - Otherwise, if you want to serve your content through CloudFront:

      - Create a distribution and add `index.html` as the default root object
      - Setup and origin access control like [here](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
      - Create a distribution invalidation that points to the object path `/*` so that CloudFront removes the previous file from cache before it expires. This way, users will get the latest app version when CI/CD process finishes
      - Use your CloudFront distribution to get the micro frontends JS code, favicon and other files needed, instead of using the default URL provided by S3.
      - Add new step at `.github/workflows/main.yml` in order to invalidate cache from CloudFront build files. Setup DISTRIBUTION_ID at repository secrets

      ```yml
        - name: Invalidate cache in CloudFront
        run: aws cloudfront create-invalidation --distribution-id "${DISTRIBUTION_ID}" --paths "/path1" "/example-path-2*" --no-cli-pager
        env:
          DISTRIBUTION_ID: ${{ secrets.DISTRIBUTION_ID }}
      ```

      - Change your bucket policy to make sure users can access the content in the bucket only through the specified CloudFront distribution

    ```
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "AllowCloudFrontServicePrincipalReadOnly",
          "Effect": "Allow",
          "Principal": {
            "Service": "cloudfront.amazonaws.com"
          },
          "Action": "s3:GetObject",
          "Resource": "arn:aws:s3:::${YOUR_BUCKET_NAME}/*",
          "Condition": {
            "StringEquals": {
              "AWS:SourceArn": "arn:aws:cloudfront::${AWS_ACCOUNT_ID}:distribution/${CLOUDFRONT_DISTRIBUTION_ID}"
            }
          }
        }
      ]
    }
    ```

    - Add CORS setting so that the root module can fetch your bucket files from local dev machine or production and dev servers

    ```
    [
      {
          "AllowedHeaders": [
              "Authorization"
          ],
          "AllowedMethods": [
              "GET",
              "HEAD"
          ],
          "AllowedOrigins": [
              "http://localhost:9000",
              "http://${BUCKET_NAME}.s3-website-us-east-1.amazonaws.com"",
              "https://{WEB_SERVER_DOMAIN_2}",
          ],
          "ExposeHeaders": [
              "Access-Control-Allow-Origin"
          ]
      }
    ]
    ```

    - Finally, add your compiled root code at the import maps and the micro frontends JS code, according to the environment

    ```html
    <% if (isLocal) { %>
    <script type="systemjs-importmap">
      {
        "imports": {
          "@${PROJECT_NAME}/root-config": "//localhost:9000/${PROJECT_NAME}-root-config.js",
          "@${PROJECT_NAME}/{MICRO_FRONTENDS_NAME}": "//localhost:${YOUR_PORT}/${PROJECT_NAME}-{MICRO_FRONTENDS_NAME}.js"
        }
      }
    </script>
    <% } else { %>
    <script type="systemjs-importmap">
      {
        "imports": {
          "@${PROJECT_NAME}/root-config": "https://{S3_BUCKET_NAME}.s3.amazonaws.com/${PROJECT_NAME}-root-config.js",
          "@${PROJECT_NAME}/{MICRO_FRONTENDS_NAME}": "https://{S3_BUCKET_NAME}.s3.amazonaws.com/${PROJECT_NAME}-{MICRO_FRONTENDS_NAME}.js"
        }
      }
    </script>
    <% } %>
    ```
