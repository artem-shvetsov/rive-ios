//
//  RiveArtboard.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveRuntime/RiveRuntime-Swift.h>

// MARK: - Globals

static int artInstanceCount = 0;

// MARK: - RiveArtboard
@interface RiveArtboard ()

/// Holds references to SMIInputs
@property NSMutableDictionary* inputs;

@end

@implementation RiveArtboard
{
    std::unique_ptr<rive::ArtboardInstance> _artboardInstance;
}

- (rive::ArtboardInstance*)artboardInstance
{
    return _artboardInstance.get();
}

// MARK: LifeCycle

- (instancetype)initWithArtboard:
    (std::unique_ptr<rive::ArtboardInstance>)riveArtboard
{
    if (self = [super init])
    {

#if RIVE_ENABLE_REFERENCE_COUNTING
        [RiveArtboard raiseInstanceCount];
#endif // RIVE_ENABLE_REFERENCE_COUNTING

        _inputs = [[NSMutableDictionary alloc] init];
        _artboardInstance = std::move(riveArtboard);
        return self;
    }
    else
    {
        return NULL;
    }
}

- (void)dealloc
{
#if RIVE_ENABLE_REFERENCE_COUNTING
    [RiveArtboard reduceInstanceCount];
#endif // RIVE_ENABLE_REFERENCE_COUNTING

    _artboardInstance.reset(nullptr);
}

// MARK: Reference Counting

+ (int)instanceCount
{
    return artInstanceCount;
}

+ (void)raiseInstanceCount
{
    artInstanceCount++;
    NSLog(@"+ Artboard: %d", artInstanceCount);
}

+ (void)reduceInstanceCount
{
    artInstanceCount--;
    NSLog(@"- Artboard: %d", artInstanceCount);
}

// MARK: C++ Bindings

- (NSInteger)animationCount
{
    return _artboardInstance->animationCount();
}

- (RiveLinearAnimationInstance*)animationFromIndex:(NSInteger)index
                                             error:(NSError**)error
{
    if (index < 0 || index >= [self animationCount])
    {
        *error = [NSError
            errorWithDomain:RiveErrorDomain
                       code:RiveNoAnimationFound
                   userInfo:@{
                       NSLocalizedDescriptionKey : [NSString
                           stringWithFormat:@"No Animation found at index %ld.",
                                            (long)index],
                       @"name" : @"NoAnimationFound"
                   }];
        return nil;
    }
    return [[RiveLinearAnimationInstance alloc]
        initWithAnimation:_artboardInstance->animationAt(index)];
}

- (RiveLinearAnimationInstance*)animationFromName:(NSString*)name
                                            error:(NSError**)error
{
    std::string stdName = std::string([name UTF8String]);
    auto animation = _artboardInstance->animationNamed(stdName);
    if (animation == nullptr)
    {
        *error = [NSError
            errorWithDomain:RiveErrorDomain
                       code:RiveNoAnimationFound
                   userInfo:@{
                       NSLocalizedDescriptionKey : [NSString
                           stringWithFormat:@"No Animation found with name %@.",
                                            name],
                       @"name" : @"NoAnimationFound"
                   }];
        return nil;
    }
    return [[RiveLinearAnimationInstance alloc]
        initWithAnimation:std::move(animation)];
}

- (NSArray*)animationNames
{
    NSMutableArray* animationNames = [NSMutableArray array];
    for (NSUInteger i = 0; i < [self animationCount]; i++)
    {
        RiveLinearAnimationInstance* animation = [self animationFromIndex:i
                                                                    error:nil];
        if (animation != nil)
        {
            [animationNames addObject:[animation name]];
        }
    }
    return animationNames;
}

/// Returns the number of state machines in the artboard
- (NSInteger)stateMachineCount
{
    return _artboardInstance->stateMachineCount();
}

/// Returns a state machine at the given index, or null if the index is invalid
- (RiveStateMachineInstance*)stateMachineFromIndex:(NSInteger)index
                                             error:(NSError**)error
{
    if (index < 0 || index >= [self stateMachineCount])
    {
        *error =
            [NSError errorWithDomain:RiveErrorDomain
                                code:RiveNoStateMachineFound
                            userInfo:@{
                                NSLocalizedDescriptionKey : [NSString
                                    stringWithFormat:
                                        @"No State Machine found at index %ld.",
                                        (long)index],
                                @"name" : @"NoStateMachineFound"
                            }];
        return nil;
    }
    return [[RiveStateMachineInstance alloc]
        initWithStateMachine:_artboardInstance->stateMachineAt(index)];
}

/// Returns a state machine with the given name, or null if none exists
- (RiveStateMachineInstance*)stateMachineFromName:(NSString*)name
                                            error:(NSError**)error
{
    std::string stdName = std::string([name UTF8String]);
    auto machine = _artboardInstance->stateMachineNamed(stdName);
    if (machine == nullptr)
    {
        *error = [NSError
            errorWithDomain:RiveErrorDomain
                       code:RiveNoStateMachineFound
                   userInfo:@{
                       NSLocalizedDescriptionKey : [NSString
                           stringWithFormat:
                               @"No State Machine found with name %@.", name],
                       @"name" : @"NoStateMachineFound"
                   }];
        return nil;
    }
    return [[RiveStateMachineInstance alloc]
        initWithStateMachine:std::move(machine)];
}

- (RiveStateMachineInstance*)defaultStateMachine
{
    auto machine = _artboardInstance->defaultStateMachine();
    if (machine == nullptr)
    {
        //        *error = [NSError errorWithDomain:RiveErrorDomain
        //        code:RiveNoStateMachineFound
        //        userInfo:@{NSLocalizedDescriptionKey: [NSString
        //        stringWithFormat: @"No default State Machine found."],
        //        @"name": @"NoStateMachineFound"}];
        return nil;
    }
    return [[RiveStateMachineInstance alloc]
        initWithStateMachine:std::move(machine)];
}

- (NSArray*)stateMachineNames
{
    NSMutableArray* stateMachineNames = [NSMutableArray array];
    for (NSUInteger i = 0; i < [self stateMachineCount]; i++)
    {
        RiveStateMachineInstance* stateMachine =
            [self stateMachineFromIndex:i error:nil];
        if (stateMachine != nil)
        {
            [stateMachineNames addObject:[stateMachine name]];
        }
    }
    return stateMachineNames;
}

- (void)advanceBy:(double)elapsedSeconds
{
    [RiveLogger logArtboard:self advance:elapsedSeconds];
    _artboardInstance->advance(elapsedSeconds);
}

- (void)draw:(RiveRenderer*)renderer
{
    _artboardInstance->draw([renderer renderer]);
}

- (NSString*)name
{
    std::string str = _artboardInstance->name();
    return [NSString stringWithCString:str.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (CGRect)bounds
{
    rive::AABB aabb = _artboardInstance->bounds();
    return CGRectMake(aabb.minX, aabb.minY, aabb.width(), aabb.height());
}

- (RiveTextValueRun*)textRun:(NSString*)name
{
    const std::string stdName = std::string([name UTF8String]);
    auto riveTextRun = _artboardInstance->find<rive::TextValueRun>(stdName);
    if (riveTextRun != nullptr)
    {
        return [[RiveTextValueRun alloc]
            initWithTextValueRun:std::move(riveTextRun)];
    }
    return nullptr;
}

- (RiveTextValueRun*)textRun:(NSString*)name path:(NSString*)path
{
    if (path.length == 0)
    {
        return [self textRun:name];
    }

    const std::string stdName = std::string([name UTF8String]);
    const std::string stdPath = std::string([path UTF8String]);
    // Can we update the cpp library to handle empty paths / default to parent
    // if nullptr?
    auto riveTextRun = _artboardInstance->getTextRun(stdName, stdPath);
    if (riveTextRun != nullptr)
    {
        return [[RiveTextValueRun alloc]
            initWithTextValueRun:std::move(riveTextRun)];
    }
    return nullptr;
}

- (RiveSMIBool*)getBool:(NSString*)name path:(NSString*)path
{
    // Create a unique dictionary name for nested artboards + booleans;
    // this lets us use one dictionary for the three different types
    NSString* dictName =
        [NSString stringWithFormat:@"%@%s%@%s", path, "_", name, "_boo"];
    // Check if the input is already instanced
    if ([_inputs objectForKey:dictName] != nil)
    {
        return _inputs[dictName];
    }
    // Otherwise, try to retrieve from runtime
    std::string stdName = std::string([name UTF8String]);
    std::string stdPath = std::string([path UTF8String]);
    rive::SMIBool* smi = _artboardInstance->getBool(stdName, stdPath);
    if (smi == nullptr)
    {
        [RiveLogger
            logArtboard:self
                  error:[NSString
                            stringWithFormat:
                                @"Could not find input named %@ at path %@",
                                name,
                                path]];
        return NULL;
    }
    else
    {
        _inputs[dictName] = [[RiveSMIBool alloc] initWithSMIInput:smi];
        return _inputs[dictName];
    }
}

- (RiveSMITrigger*)getTrigger:(NSString*)name path:(NSString*)path
{
    // Create a unique dictionary name for nested artboards + triggers;
    // this lets us use one dictionary for the three different types
    NSString* dictName =
        [NSString stringWithFormat:@"%@%s%@%s", path, "_", name, "_trg"];
    // Check if the input is already instanced
    if ([_inputs objectForKey:dictName] != nil)
    {
        return _inputs[dictName];
    }
    // Otherwise, try to retrieve from runtime
    std::string stdName = std::string([name UTF8String]);
    std::string stdPath = std::string([path UTF8String]);
    rive::SMITrigger* smi = _artboardInstance->getTrigger(stdName, stdPath);
    if (smi == nullptr)
    {
        [RiveLogger
            logArtboard:self
                  error:[NSString
                            stringWithFormat:
                                @"Could not find input named %@ at path %@",
                                name,
                                path]];
        return NULL;
    }
    else
    {
        _inputs[dictName] = [[RiveSMITrigger alloc] initWithSMIInput:smi];
        return _inputs[dictName];
    }
}

- (RiveSMINumber*)getNumber:(NSString*)name path:(NSString*)path
{
    // Create a unique dictionary name for nested artboards + numbers;
    // this lets us use one dictionary for the three different types
    NSString* dictName =
        [NSString stringWithFormat:@"%@%s%@%s", path, "_", name, "_num"];
    // Check if the input is already instanced
    if ([_inputs objectForKey:dictName] != nil)
    {
        return _inputs[dictName];
    }
    // Otherwise, try to retrieve from runtime
    std::string stdName = std::string([name UTF8String]);
    std::string stdPath = std::string([path UTF8String]);
    rive::SMINumber* smi = _artboardInstance->getNumber(stdName, stdPath);
    if (smi == nullptr)
    {
        [RiveLogger
            logArtboard:self
                  error:[NSString
                            stringWithFormat:
                                @"Could not find input named %@ at path %@",
                                name,
                                path]];
        return NULL;
    }
    else
    {
        _inputs[dictName] = [[RiveSMINumber alloc] initWithSMIInput:smi];
        ;
        return _inputs[dictName];
    }
}

- (float)volume
{
    return _artboardInstance->volume();
}

- (void)setVolume:(float)volume
{
    _artboardInstance->volume(volume);
}

- (double)width
{
    return _artboardInstance->width();
}

- (double)height
{
    return _artboardInstance->height();
}

- (void)setWidth:(double)value
{
    _artboardInstance->width(value);
}

- (void)setHeight:(double)value
{
    _artboardInstance->height(value);
}

- (void)resetArtboardSize
{
    _artboardInstance->width(_artboardInstance->originalWidth());
    _artboardInstance->height(_artboardInstance->originalHeight());
}

#pragma mark - Data Binding

- (void)bindViewModelInstance:(RiveDataBindingViewModelInstance*)instance
{
    // Let's walk through the instances of the word instance
    //
    // _artboardInstance is the underlying c++ type of ourself
    // to which we bind
    //
    // instance is the ObjC bridging type of the underlying
    // c++ type of a view model instance.
    //
    // instance.instance is the underlying c++ type of the bridging type
    // so that we can call into the c++ runtime
    //
    // instance.instance->instance() is the c++ rcp of the actual
    // type that gets bound to the artboard
    _artboardInstance->bindViewModelInstance(instance.instance->instance());
    [RiveLogger logArtboard:self instanceBind:instance.name];
}

@end
