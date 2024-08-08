# Steps to reproduce

0. Export variables:
    ```
    export OVH_ENDPOINT=ovh-eu
    export OVH_APPLICATION_KEY=***
    export OVH_APPLICATION_SECRET=***
    export OVH_CONSUMER_KEY==***
    ```

1. Bootstrap Project and s3 user: 
    ```
    terraform apply --var="customer_name=my-dummy-customer";
    ```

2. Activate creation of s3 buckets:
    ```
    mv s3.tf.deactivated s3.tf
    ```

3. Create s3 buckets. Retry, if this fails. If it fails consistently try changing the customer name, this will change the bucket names:
    ```
    terraform apply --var="customer_name=my-dummy-customer"
    ```

4. Run terraform apply in a loop until an error occurs:
    ```
    date; while terraform apply --auto-approve --var="customer_name=my-dummy-customer"; do date; done ; date
    ```

# Teardown

To teardown the resources use:
```
terraform destroy --var="customer_name=my-dummy-customer"
```
