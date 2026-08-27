# Landing Zone 커스터마이징

## 소개

OCI Core Landing Zone은 완성된 단일 제품이라기보다는, OCI를 시작할때 안전하고 확장 가능한 환경을 시작하기 위한 청사진(Blueprint)이자 참조 아키텍처(reference architecture)입니다. [OCI Curated Landing Zone Blueprints](https://docs.oracle.com/en-us/iaas/Content/cloud-adoption-framework/oci-landing-zones-overview.htm)과 [OCI Core Landing Zone](https://docs.oracle.com/en-us/iaas/Content/cloud-adoption-framework/oci-core-landing-zone.htm) 문서에서 Landing Zone은 클라우드 도입을 위한 모범 사례 기반 시작점으로 그대로 사용하거나, 이를 활용해 맞춤형(build-your-own landing zone)으로 구축하라고 이야기하고 있습니다.

즉, Core Landing Zone과 Extensions는 기본 골격을 빠르게 만드는 데 매우 유용하지만, 실제 운영에서는 조직의 보안 정책, 워크로드 유형, 서비스 사용 범위에 맞춰 원하는 형태로 발전시켜야 합니다. 이번 실습에서는 앞서 배포한 Workload IAM Extension에 추가 IAM Policy statement를 넣고 재배포하는 방식으로 커스터마이징하는 아주 간단한 흐름을 연습합니다.

예상 실습 시간: 20분

### 목표

이 실습에서는 다음을 수행합니다.

- Core Landing Zone을 참조 아키텍처(reference architecture)로 이해
- Terraform으로 관리되는 Landing Zone 리소스를 커스터마이징하는 방법 이해
- Workload IAM Extension에 추가 policy statement 입력
- Plan 결과에서 IAM Policy만 변경되는지 확인
- Apply 후 추가 권한이 반영되었는지 검사

### 사전 준비 사항

- 앞선 실습에서 Core Landing Zone Stack이 성공적으로 배포되어 있어야 합니다.
- Workload IAM Extension Stack이 배포되어 있어야 합니다.
- Workload IAM Extension에서 사용한 `Service Label`, `Workload Compartment Name`, App Admin Group 이름을 알고 있어야 합니다.
- Resource Manager Stack의 Terraform configuration을 수정할 수 있는 권한이 필요합니다.

## 작업 1: 왜 커스터마이징이 필요한지 이해

Core Landing Zone은 컴파트먼트, IAM 그룹, 정책, 네트워크, 보안/로깅 서비스를 모범 사례 기반으로 구성합니다. 하지만 모든 조직의 워크로드 요구 사항을 하나의 기본 템플릿이 완전히 충족할 수는 없습니다.

특히 서비스 관련 정책(IAM Policy)이 워크로드 요구사항에 따라 달라질텐데, 철저히 관리할 것인가? 편의상 컴파트먼트 레벨에서는 정책을 직접 관리하게 할 것인가?

여기서는 일단은 서비스 관련 정책(IAM Policy)을 관리하고, 기본적으로 필요하다고 판단되는 정책을 기본 설정해서 제공하는 경우인데, OCI Core Landing Zone에서 Workload 관리자에게 제공하지 않는 기능이 있는데, 추가할 필요가 있다는 상황하에, 이 실습에서는 기본 IAM Extension 정책에 포함되지 않은 서비스 권한의 예시로, OCI Container Instance 서비스을 추가하려고 합니다.

## 작업 2: 추가할 Policy Statement 정하기

이번 실습에서는 Workload Admin, Workload App Admin 그룹이 workload 컴파트먼트 안에서 OCI DevOps 리소스를 관리할 수 있도록 권한을 추가합니다.

- [Container Instances IAM Policies](https://docs.oracle.com/en-us/iaas/Content/container-instances/permissions/policy-reference.htm) 문서상에 예시로 설명된 문장으로 다음과 같습니다.

    ```text
    Allow group ContainerInstanceLaunchers to manage compute-container-family in compartment <container-instance-compartment-name>
    ```

## 작업 3: IAM Extension Stack의 Terraform 설정 수정

1. IAM Extension 배포용 Stack에서 Edit > Edit Terraform configuration in code editor를 클릭하여 Code Editor를 실행합니다.

2. RESOURCE MANAGER 플러그에서 포괄(Enclosing) 컴파트먼트 아래에 있는 stack에서 IAM Extension 배포용 Stack에서 iam_polices.tf 파일을 엽니다.

3. 85줄로 기존 형식에 맞게 아래와 같이 compute-container-family 권한을 wkld_admin에게 추가합니다.

    ```
    60  wkld_admin_policy_statements = var.deploy_wkld_policies ? concat([
        ...
    85    "allow group ${local.wkld_admin_group_name} to manage compute-container-family in compartment ${local.service_label_workload_compartment_name}",
    86    "allow group ${local.wkld_admin_group_name} to manage secret-family in compartment ${local.service_label_workload_compartment_name}"    
    87    ],
    ```

4. 159줄로 기존 형식에 맞게 아래와 같이 compute-container-family 권한을 wkld_app_admin에게 추가합니다.

    ```
    132  app_admin_policy_statements = concat(
            ...
    158     "allow group ${local.app_admin_group_name} to manage compute-container-family in compartment ${local.app_main_policy_cmp}",
    159     "allow group ${local.app_admin_group_name} to read database-family in compartment ${local.app_main_policy_cmp}"
    160    ],
    ```

5. Stack에 우클릭하고 Save changes and run Plan action을 클릭합니다.

6. OCI 콘솔 Stack 화면에서 Jobs에서 Plan이 실행된 것을 확인합니다.

## 작업 4: Apply 실행

1. Plan 결과가 의도한 내용과 일치하면 *Stack details* 페이지로 돌아갑니다.
1. Actions의 __Apply__ 버튼을 클릭합니다.
1. __Apply job plan resolution__ 드롭다운에서 방금 만든 Plan을 선택합니다.
1. __Apply__를 클릭합니다.
1. Apply가 완료되면 로그에서 오류가 없는지 확인합니다.

## 작업 6: 추가 Policy 검사

1. *Stack details* 페이지의 Stack resources 탭에서 보이는 목록에서 Workload App Admin Policy(예, hol-workload-1-app-admin-policy)를 찾습니다.
1. Policy 리소스를 클릭하여 상세 페이지로 이동합니다.
1. Statements 탭을 클릭하여, Policy statements 목록에 다음 형태의 statement가 추가되었는지 확인합니다.

    ```text
    allow group hol-workload-1-app-admin-group to read database-family in compartment hol-workload-1-cmp
    ```

1. *Identity & Security* > *Policies*로 이동하여 동일한 policy를 직접 찾아도 됩니다.

## 작업 7: 커스터마이징 원칙 정리

Landing Zone 커스터마이징은 “기본 템플릿을 한번 배포하고 끝”이 아니라, 조직의 운영 모델에 맞춰 지속적으로 다듬는 과정입니다.

- Core Landing Zone은 안전한 시작점이자 참조 아키텍처(reference architecture)입니다.
- 실제 운영에서는 조직별 네트워크, IAM, 보안, 감사 요구 사항에 맞게 조정해야 합니다.
- Terraform으로 만든 리소스는 Terraform으로 변경하는 것이 좋습니다.
- 워크로드 배포시 기본적으로 필요한 정책은 Extension을 커스터마이징해는 것이 좋을까요?
- 워크로드별도 필요한 추가 정책은 hol-workload-1-app-admin-custom-policy과 같이 이름짓고, 그때그때마다 추가하는 게 좋을까요?

이번 실습에서는 IAM Extension의 추가 policy 변수를 사용했지만, 같은 원칙은 네트워크 라우팅, NSG, 보안 서비스, 관측성 설정에도 적용됩니다. 그리고 쉬운 예시로 IAM Extension을 수정배포 했지만, 메인 모듈을 커스터마이징하는 것도 있을 수 있습니다. 중요한 것은 Landing Zone을 조직의 표준 운영 단위로 만들고, 그 변경 이력을 Terraform과 Resource Manager Stack에 남기는 것입니다.

## 감사의 말 (Acknowledgements)

* **Author:** DongHee Lee
* **Last Updated By/Date:** DongHee Lee, July 2026
