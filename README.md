## Convert to BASE64
```echo -n 'super-secret-password' | base64```

## Restart Pod
```kubectl rollout restart deployment <deployment_name> -n <namespace>```