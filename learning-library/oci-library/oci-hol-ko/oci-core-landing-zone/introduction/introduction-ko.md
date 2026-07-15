# 소개

## 1. 워크샵 소개

![OCI Core Landing Zone 로고](images/landing-zone-icon.png "Oracle 모양 랜딩 패드에 접근하는 헬리콥터의 OCI Core Landing Zone 로고")

이 실습 모음에서는 [CIS OCI Foundations Benchmark v3.0](https://www.cisecurity.org/benchmark/oracle_cloud/)을 준수하는 안전한 클라우드 아키텍처를 배포하는 과정을 안내합니다. 실습을 완료하면 안전한 엔터프라이즈 워크로드를 구축하기 위한 기반으로 사용할 수 있는 OCI 리소스 전체 세트가 생성됩니다.

예상 워크숍 시간: 1시간 30분

### 목표

- Terraform 파일을 OCI Resource Manager에 업로드
- Landing Zone을 사용자 지정하기 위한 변수 구성
- Terraform Plan 생성 및 검사
- Plan을 OCI 테넌시에 적용
- Terraform으로 Landing Zone 수정
- 초기화를 위한 Terraform Destroy 수행

### 사전 준비 사항

이 실습에는 다음 사전 준비 사항이 필요합니다.

- [Free Tier](https://www.oracle.com/cloud/free/) 또는 Paid OCI tenancy
- OCI의 Administrators 그룹에 속한 IAM User

## 2. OCI Core Landing Zone 아키텍처

### 개요

OCI Core Landing Zone은 [GitHub에 공개 호스팅된](https://github.com/oci-landing-zones/terraform-oci-core-landingzone) 아키텍처 및 관련 Terraform 파일입니다. 결과물은 [variables.tfvars](https://github.com/oci-landing-zones/terraform-oci-core-landingzone/blob/main/VARIABLES.md) 파일의 구성을 변경하거나, 이 실습에서처럼 Terraform 코드를 [OCI Resource Manager](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm)에 입력하고 Resource Manager에서 제공되는 GUI에서 구성을 입력하여 수정할 수 있습니다. 이렇게 하면 OCI에서 개발 또는 운영 워크로드를 위한 보안 기준선으로 사용할 전체 리소스 세트가 프로비저닝됩니다.

### 비용

Landing Zone에서 배포하는 모든 리소스는 포함 서비스이므로 비용 없이 제공됩니다. 단, 이 실습에서 사용하지 않을 한 가지 예외가 있습니다.

### 아키텍처 구성 요소

Landing Zone은 운영 클라우드에 적합한 전체 리소스 세트를 배포합니다. 여기에는 다음이 포함됩니다.

- Identity and Access Management(IAM) Controls
- 하나 이상의 Virtual Cloud Network(VCN)
- Logging 서비스
- OCI Bastion 서비스
- Cloud Events 규칙
- Alarms
- OCI Notifications
- OCI Object Storage
- Budget Controls

결과 아키텍처는 다음 다이어그램과 유사합니다.
아래 다이어그램은 다른 네트워크 환경에 연결되지 않은 독립적으로 운영되는 독립형(Standalone) VCN 배포 구성 예시입니다.
![단순 아키텍처](images/arch-simple.svg "단순 Landing Zone 아키텍처")

### IAM 구성 요소

Landing Zone의 가장 좋은 기능 중 하나는 미리 정의된 그룹, 정책, 컴파트먼트 세트가 자동으로 생성된다는 점입니다. 이러한 리소스는 대부분의 사용 사례에 맞도록 만들어졌으며 [직무 분리](#직무-분리에-대하여)를 실행하기 위한 견고한 기반을 제공합니다.

#### 컴파트먼트

[컴파트먼트](https://www.ateam-oracle.com/post/oracle-cloud-infrastructure-compartments)는 여러 리소스를 담는 유연한 논리 컨테이너입니다. Core Landing Zone에서는 관리 역할을 기준으로 리소스를 분리하여 직무 분리를 가능하게 하기 위해 컴파트먼트를 사용합니다. 각 그룹은 담당 업무에 따라 이러한 컴파트먼트에 대한 권한을 부여받습니다. 선택 사항이지만 권장되는 포괄 컴파트먼트를 구성할 수 있으므로, 하나의 클라우드 테넌시에 여러 Landing Zone을 배포할 수 있습니다. 일반적인 사용 사례는 환경 유형(개발, 테스트, 운영)에 따라 포괄 컴파트먼트를 사용하고, 각 환경의 포괄 컴파트먼트 안에 서로 다른 Landing Zone을 두는 것입니다.

컴파트먼트에는 다음이 포함됩니다.

- Network
- Security
- Application Development
- Database
- _Exadata(선택 사항)_

#### 그룹

그룹은 권한이 부여되는 IAM 객체입니다. 그룹에는 하나 이상의 멤버가 포함됩니다. 사용자는 그룹 멤버십을 통해 OCI에서 다양한 기능을 수행할 수 있습니다. 권한이 할당된 그룹에 하나 이상 속해 있지 않으면 사용자는 OCI 내에서 어떤 권한도 갖지 않습니다.

Landing Zone에서 프로비저닝되는 그룹은 다음과 같습니다.

- Network Admins
- Security Admins
- AppDev(Application Development) Admins
- Database Admins
- IAM Admins
- Cost Admins
- Auditors
- Cred Admins
- Announcement Readers
- Access Gov Admins
- Storage Admins
- _Exadata Admins(선택 사항)_

#### 정책

OCI에서 그룹, 컴파트먼트, 권한을 연결하는 요소를 [_정책_](https://docs.oracle.com/en-us/iaas/Content/Identity/policieshow/how-policies-work.htm#how_policies_work)이라고 합니다. 정책은 그룹, 위치(컴파트먼트), 리소스(또는 리소스 집합), 접근 수준을 정의하는 동사를 결합한 사람이 읽을 수 있는 명령문입니다. 기본적인 문법은 다음과 같습니다.

```Allow <subject> to <verb> <resource> in <location>```

테넌트 수준 Administrator 접근 권한을 정의하는 정책은 Tenant Admin Policy란 이름으로 Root 컴파트먼트에 다음과 같이 설정되어 있습니다.

```ALLOW GROUP Administrators to manage all-resources IN TENANCY```

이 정책은 테넌트의 모든 컴파트먼트를 포함하므로 `<location>`에 __TENANCY__를 사용합니다. _SampleAdmins_ 그룹에 Sample 컴파트먼트의 모든 리소스에 대한 전체 제어 권한을 부여하려면 다음과 같습니다.

```Allow group ExampleAdmins to manage all-resources in compartment Example```

이는 가장 간단한 예시입니다. OCI 정책에 대한 더 자세한 설명은 [IAM Policies Overview 문서](https://docs.oracle.com/en-us/iaas/Content/Identity/policieshow/Policy_Basics.htm)에서 확인할 수 있습니다.

## 3. 직무 분리에 대하여

Landing Zone과 관련된 직무 분리 원칙에 대해 간단히 짚고 넘어가겠습니다. 모든 리소스에 대한 전체 접근 권한을 가진 관리자는 보안을 유지하기 위해 최소한으로 제한해야 합니다. 오남용을 방지하기 위해 책임은 여러 사람과 역할에 분산되어야 합니다. 관리자는 최소 권한 원칙에 따라 담당 업무를 수행하는 데 필요한 최소한의 권한만 부여받아야 합니다. Landing Zone은 이 개념을 중심으로 설계되었으며, 이는 컴파트먼트와 IAM 객체(그룹, 사용자, 정책) 설계의 핵심 아이디어입니다.

조직 전반의 일반적인 역할을 수행할 수 있도록 유용한 기본 그룹 세트를 제공하려는 노력이 반영되어 있습니다. 그러나 이 구성이나 어떤 애플리케이션도 사용자 지정 없이 가능한 모든 구성에 맞기는 어렵습니다. 이러한 그룹의 권한을 규정하는 정책은 조직의 필요에 맞게 수정해야 합니다. 하지 말아야 할 일은 특정 개인에게 모든 역할을 할당하여 과도한 권한을 부여하는 것입니다.

## 4. Terraform에 대한 참고 사항

OCI Core Landing Zone은 [Terraform](https://developer.hashicorp.com/terraform/intro)을 사용하여 모든 리소스를 테넌시에 배포합니다. Terraform은 자동화를 통해 클라우드 객체를 프로비저닝하는 데 사용하는 Infrastructure as Code 도구입니다. Terraform을 이용해 Landing Zone을 자동으로 구축함으로써, OCI에서 운영 가능한 환경을 준비하는 시간이 단축됩니ㄷ.

Terraform은 다양한 배포 방식에 맞게 여러 클라이언트와 함께 사용할 수 있습니다. 이 실습에서는 OCI에서 Terraform 사용을 단순화하기 위해 [OCI Resource Manager](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm)를 활용합니다. OCI Resource Manager는 Oracle에서 관리하는 Terraform 서비스로, 구성 파일을 사용하여 Terraform 기반 리소스의 배포와 운영을 자동화합니다. Terraform 사용의 복잡성을 줄이고, 상태 파일을 개발자 노트북이 아닌 클라우드에 저장할 수 있게 해 줍니다.

OCI의 대부분 항목은 Terraform으로 프로비저닝할 수 있습니다. 이 실습 범위를 벗어나지만, [OCI에서 Terraform 사용](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraform.htm)에 대한 추가 정보를 확인할 수 있습니다.

## 감사의 말 (Acknowledgements)

* **Author:** KC Flynn
* **Contributors:** Andre Correa, Johannes Murmann, Josh Hammer, Olaf Heimburger
* **Korean Translator & Contributors:** DongHee Lee, July 2026
* **Last Updated By/Date:** DongHee Lee, July 2026